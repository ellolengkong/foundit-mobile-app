import { createClient } from "npm:@supabase/supabase-js@2";

type NotificationRecord = {
  id: string;
  user_id: string;
  notification_type: string;
  title: string;
  body: string;
  report_id: string | null;
};

type WebhookPayload = {
  type?: string;
  table?: string;
  schema?: string;
  record?: NotificationRecord | null;
};

type FirebaseServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
};

const channelId = "foundit_notifications";
let cachedAccessToken: string | undefined;
let cachedAccessTokenExpiry = 0;

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function equalSecret(actual: string, expected: string): boolean {
  if (actual.length !== expected.length) return false;
  let difference = 0;
  for (let index = 0; index < actual.length; index++) {
    difference |= actual.charCodeAt(index) ^ expected.charCodeAt(index);
  }
  return difference === 0;
}

function base64UrlEncode(value: Uint8Array): string {
  let binary = "";
  for (const byte of value) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_")
    .replaceAll("=", "");
}

function encodeJson(value: Record<string, unknown>): string {
  return base64UrlEncode(new TextEncoder().encode(JSON.stringify(value)));
}

function decodePrivateKey(value: string): Uint8Array {
  const base64 = value
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s/g, "");
  const binary = atob(base64);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

async function getFirebaseAccessToken(
  account: FirebaseServiceAccount,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessTokenExpiry - now > 60) {
    return cachedAccessToken;
  }

  const unsignedToken = [
    encodeJson({ alg: "RS256", typ: "JWT" }),
    encodeJson({
      iss: account.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  ].join(".");
  const signingKey = await crypto.subtle.importKey(
    "pkcs8",
    decodePrivateKey(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      signingKey,
      new TextEncoder().encode(unsignedToken),
    ),
  );
  const assertion = `${unsignedToken}.${base64UrlEncode(signature)}`;
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!tokenResponse.ok) {
    console.error("Firebase OAuth token request failed:", tokenResponse.status);
    throw new Error("Unable to authenticate with Firebase.");
  }

  const tokenData = await tokenResponse.json();
  if (typeof tokenData.access_token !== "string") {
    throw new Error("Firebase did not return an access token.");
  }
  cachedAccessToken = tokenData.access_token;
  cachedAccessTokenExpiry = now + Number(tokenData.expires_in ?? 3600);
  return cachedAccessToken;
}

function isUnregisteredToken(response: {
  status?: string;
  details?: Array<{ errorCode?: string }>;
}): boolean {
  return response.status === "UNREGISTERED" ||
    response.details?.some((detail) => detail.errorCode === "UNREGISTERED") ===
      true;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const expectedSecret = Deno.env.get("PUSH_WEBHOOK_SECRET");
  const suppliedSecret = request.headers.get("x-push-webhook-secret");
  if (
    !expectedSecret || !suppliedSecret ||
    !equalSecret(suppliedSecret, expectedSecret)
  ) {
    return jsonResponse({ error: "Unauthorized." }, 401);
  }

  let payload: WebhookPayload;
  try {
    payload = await request.json() as WebhookPayload;
  } catch {
    return jsonResponse({ error: "Invalid webhook payload." }, 400);
  }

  const record = payload.record;
  if (
    payload.type !== "INSERT" || payload.table !== "notifications" ||
    payload.schema !== "public" || !record?.id || !record.user_id ||
    !record.title || !record.body
  ) {
    return jsonResponse({ error: "Unsupported webhook event." }, 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const serviceAccountValue = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!supabaseUrl || !serviceRoleKey || !serviceAccountValue) {
    console.error("Push function configuration is incomplete.");
    return jsonResponse({ error: "Push service is not configured." }, 500);
  }

  let serviceAccount: FirebaseServiceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountValue) as FirebaseServiceAccount;
  } catch {
    console.error("Firebase service account secret is not valid JSON.");
    return jsonResponse({ error: "Push service is not configured." }, 500);
  }
  if (
    !serviceAccount.client_email || !serviceAccount.private_key ||
    !serviceAccount.project_id
  ) {
    console.error("Firebase service account secret is incomplete.");
    return jsonResponse({ error: "Push service is not configured." }, 500);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: devices, error: deviceError } = await supabase
    .from("push_device_tokens")
    .select("token")
    .eq("user_id", record.user_id);
  if (deviceError) {
    console.error("Unable to load push devices:", deviceError.message);
    return jsonResponse({ error: "Unable to load push devices." }, 500);
  }
  if (!devices?.length) return jsonResponse({ sent: 0, removed: 0 });

  try {
    const accessToken = await getFirebaseAccessToken(serviceAccount);
    let sent = 0;
    let removed = 0;
    let failed = 0;

    for (const device of devices) {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(serviceAccount.project_id)}/messages:send`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: device.token,
              notification: { title: record.title, body: record.body },
              data: {
                notification_id: record.id,
                notification_type: record.notification_type,
                ...(record.report_id ? { report_id: record.report_id } : {}),
              },
              android: {
                priority: "HIGH",
                notification: {
                  channel_id: channelId,
                  default_sound: true,
                },
              },
            },
          }),
        },
      );

      if (response.ok) {
        sent++;
        continue;
      }

      const errorBody = await response.json().catch(() => ({}));
      const fcmError = errorBody?.error as
        | { status?: string; details?: Array<{ errorCode?: string }> }
        | undefined;
      if (fcmError && isUnregisteredToken(fcmError)) {
        const { error } = await supabase
          .from("push_device_tokens")
          .delete()
          .eq("token", device.token);
        if (error) {
          console.error("Unable to remove an expired push token.");
          failed++;
        } else {
          removed++;
        }
      } else {
        console.error("Firebase rejected a push message:", response.status);
        failed++;
      }
    }

    return jsonResponse({ sent, removed, failed });
  } catch (error) {
    console.error(
      "Push notification dispatch failed:",
      error instanceof Error ? error.message : "unknown error",
    );
    return jsonResponse({ error: "Push notification dispatch failed." }, 500);
  }
});
