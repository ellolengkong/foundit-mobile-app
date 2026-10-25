import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Metode permintaan tidak didukung." }, 405);
  }

  const authorization = request.headers.get("Authorization");
  const accessToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!accessToken) {
    return jsonResponse({ error: "Sesi masuk tidak ditemukan." }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error("Supabase function environment is incomplete.");
    return jsonResponse({ error: "Layanan hapus akun belum dikonfigurasi." }, 500);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
  });
  const passwordClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: userData, error: userError } =
    await userClient.auth.getUser(accessToken);
  if (userError || !userData.user) {
    return jsonResponse({ error: "Sesi masuk tidak valid atau kedaluwarsa." }, 401);
  }

  let body: { password?: unknown };
  try {
    body = await request.json() as { password?: unknown };
  } catch {
    return jsonResponse({ error: "Permintaan tidak valid." }, 400);
  }

  if (typeof body.password !== "string" || body.password.length === 0) {
    return jsonResponse({ error: "Kata sandi wajib diisi." }, 400);
  }

  const { data: verifiedUser, error: passwordError } =
    await passwordClient.auth.signInWithPassword({
      email: userData.user.email ?? "",
      password: body.password,
    });
  if (passwordError || verifiedUser.user?.id !== userData.user.id) {
    return jsonResponse({ error: "Kata sandi yang dimasukkan salah." }, 401);
  }

  const reportIds: string[] = [];
  for (let offset = 0; ; offset += 1000) {
    const { data: reports, error: reportsError } = await userClient
      .from("reports")
      .select("id")
      .eq("owner_id", userData.user.id)
      .range(offset, offset + 999);
    if (reportsError) {
      console.error("Unable to list account reports:", reportsError.message);
      return jsonResponse({
        error: "Data laporan akun gagal disiapkan untuk dihapus.",
      }, 500);
    }
    reportIds.push(...(reports ?? []).map((report) => report.id as string));
    if (!reports || reports.length < 1000) break;
  }

  const photoPaths = reportIds.map((reportId) => `${reportId}/photo`);
  for (let offset = 0; offset < photoPaths.length; offset += 100) {
    const photoBatch = photoPaths.slice(offset, offset + 100);
    const { error: storageError } = await adminClient.storage
      .from("report-photos")
      .remove(photoBatch);
    if (storageError) {
      console.error(
        "Unable to remove account report photos:",
        storageError.message,
      );
      return jsonResponse({
        error: "Foto laporan gagal dihapus. Akun belum dihapus.",
      }, 500);
    }
  }

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(
    userData.user.id,
  );
  if (deleteError) {
    console.error("Unable to delete authenticated user:", deleteError.message);
    return jsonResponse({
      error: "Akun gagal dihapus. Silakan coba lagi.",
    }, 500);
  }

  return jsonResponse({ account_deleted: true });
});
