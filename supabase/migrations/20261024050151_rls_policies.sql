-- ============================================================================
-- FoundIt M2A — Migration: RLS Policies, Grants & Admin RPCs
-- Row Level Security, least-privilege column grants, and admin moderation RPCs.
-- Based on DATA_MODEL.md §8
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────────
-- 1. Enable RLS on all exposed tables
-- ──────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_flags  ENABLE ROW LEVEL SECURITY;

-- ──────────────────────────────────────────────────────────────────────────────
-- 2. Security Advisor Remediation: public.rls_auto_enable()
--    An event trigger `ensure_rls` on remote Supabase calls `public.rls_auto_enable()`.
--    Security Advisor detects this because default PostgreSQL function privileges
--    grant EXECUTE to PUBLIC / anon / authenticated.
--    Revoking EXECUTE from unprivileged roles fixes the Security Advisor finding
--    without touching or breaking the event trigger execution by postgres/superuser.
-- ──────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'rls_auto_enable'
  ) THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated';
    EXECUTE 'COMMENT ON FUNCTION public.rls_auto_enable() IS ''Event trigger function for ensure_rls. EXECUTE revoked from application roles to resolve Security Advisor warning.''';
  END IF;
END $$;

-- ──────────────────────────────────────────────────────────────────────────────
-- 3. Grants — least-privilege access with column-level restrictions
-- ──────────────────────────────────────────────────────────────────────────────

-- Revoke all table-level privileges from PUBLIC, anon, and authenticated
REVOKE ALL ON public.profiles      FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.user_contacts FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.reports       FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.report_flags  FROM PUBLIC, anon, authenticated;

-- public_reports view:
-- Readable by everyone (both anon and authenticated).
-- Exposes safe columns only, with security_barrier = true.
GRANT SELECT ON public.public_reports TO anon, authenticated;

-- profiles:
-- Authenticated users can read (RLS limits to own profile or admin).
-- Authenticated users can update ONLY full_name (role, id, timestamps cannot be changed).
GRANT SELECT ON public.profiles TO authenticated;
GRANT UPDATE (full_name) ON public.profiles TO authenticated;

-- user_contacts:
-- Private table. anon has no access.
-- Authenticated users can read their own row (RLS limits to own row).
-- INSERT is granted per column: user_id, whatsapp_number, allow_whatsapp_contact (no updated_at).
-- UPDATE is granted per column: whatsapp_number, allow_whatsapp_contact (no user_id or updated_at).
GRANT SELECT ON public.user_contacts TO authenticated;
GRANT INSERT (user_id, whatsapp_number, allow_whatsapp_contact) ON public.user_contacts TO authenticated;
GRANT UPDATE (whatsapp_number, allow_whatsapp_contact) ON public.user_contacts TO authenticated;

-- reports:
-- anon has NO access to reports table (must use public_reports view).
-- Authenticated users can SELECT (RLS limits to own reports or admin) and DELETE (own report or admin).
-- INSERT is granted ONLY on: report_type, item_name, category, description, photo_path, campus_area, building_name, specific_location, event_date.
-- id, owner_id, status, moderation_status, created_at, updated_at are EXCLUDED from INSERT grant.
-- Database defaults fill: id (gen_random_uuid), owner_id (auth.uid), status ('active'), moderation_status ('visible'), created_at/updated_at (now()).
-- UPDATE is granted ONLY on content/location fields and status (owner resolving report).
-- owner_id, moderation_status, created_at, updated_at, id are EXCLUDED from UPDATE grant.
GRANT SELECT, DELETE ON public.reports TO authenticated;
GRANT INSERT (
  report_type, item_name, category, description, photo_path,
  campus_area, building_name, specific_location, event_date
) ON public.reports TO authenticated;
GRANT UPDATE (
  report_type, item_name, category, description, photo_path,
  campus_area, building_name, specific_location, event_date, status
) ON public.reports TO authenticated;

-- report_flags:
-- Authenticated users can SELECT (own flags or admin).
-- INSERT is granted ONLY on: report_id, reporter_id, reason, details.
-- id, review_status, created_at are EXCLUDED from INSERT grant.
-- Database defaults fill: id (gen_random_uuid), review_status ('open'), created_at (now()).
-- UPDATE (review_status) is granted for the admin policy / RPC.
GRANT SELECT ON public.report_flags TO authenticated;
GRANT INSERT (
  report_id, reporter_id, reason, details
) ON public.report_flags TO authenticated;
GRANT UPDATE (review_status) ON public.report_flags TO authenticated;

-- ──────────────────────────────────────────────────────────────────────────────
-- 4. profiles policies
-- ──────────────────────────────────────────────────────────────────────────────

-- Users can read their own profile.
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
CREATE POLICY profiles_select_own
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Admin can read all profiles for moderation purposes.
DROP POLICY IF EXISTS profiles_select_admin ON public.profiles;
CREATE POLICY profiles_select_admin
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- Users can update only their own profile (column grant limits to full_name).
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    -- Prevent user from changing their own role
    AND role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid())
  );

-- ──────────────────────────────────────────────────────────────────────────────
-- 5. user_contacts policies
--    Fully private: users can only manage their own row.
--    No anon access. No cross-user direct access.
-- ──────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS user_contacts_select_own ON public.user_contacts;
CREATE POLICY user_contacts_select_own
  ON public.user_contacts
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS user_contacts_insert_own ON public.user_contacts;
CREATE POLICY user_contacts_insert_own
  ON public.user_contacts
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_contacts_update_own ON public.user_contacts;
CREATE POLICY user_contacts_update_own
  ON public.user_contacts
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ──────────────────────────────────────────────────────────────────────────────
-- 6. reports policies
--    Base table access is restricted to own reports and admin moderation.
--    Public browsing goes through public_reports view so owner_id is never leaked.
-- ──────────────────────────────────────────────────────────────────────────────

-- Authenticated users can read:
--   - Their own reports (including resolved and hidden ones)
--   - All reports if admin (for moderation inspection)
DROP POLICY IF EXISTS reports_select_authenticated ON public.reports;
DROP POLICY IF EXISTS reports_select_anon ON public.reports;
DROP POLICY IF EXISTS reports_select_own ON public.reports;
CREATE POLICY reports_select_own
  ON public.reports
  FOR SELECT
  TO authenticated
  USING (
    owner_id = auth.uid()
    OR public.is_admin()
  );

-- Authenticated users can create reports.
-- owner_id must match auth.uid() (enforced by DEFAULT + WITH CHECK).
DROP POLICY IF EXISTS reports_insert_authenticated ON public.reports;
CREATE POLICY reports_insert_authenticated
  ON public.reports
  FOR INSERT
  TO authenticated
  WITH CHECK (owner_id = auth.uid());

-- Owner can update their own report.
-- Column grant already prevents changing owner_id and moderation_status.
-- This policy additionally prevents changing moderation_status via RLS.
DROP POLICY IF EXISTS reports_update_own ON public.reports;
CREATE POLICY reports_update_own
  ON public.reports
  FOR UPDATE
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (
    owner_id = auth.uid()
    AND moderation_status = (
      SELECT r.moderation_status FROM public.reports r WHERE r.id = reports.id
    )
  );

-- Admin can update any report (general updates / fallback).
DROP POLICY IF EXISTS reports_update_admin ON public.reports;
CREATE POLICY reports_update_admin
  ON public.reports
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Owner can delete their own report.
DROP POLICY IF EXISTS reports_delete_own ON public.reports;
CREATE POLICY reports_delete_own
  ON public.reports
  FOR DELETE
  TO authenticated
  USING (owner_id = auth.uid());

-- Admin can delete reports if needed for moderation.
DROP POLICY IF EXISTS reports_delete_admin ON public.reports;
CREATE POLICY reports_delete_admin
  ON public.reports
  FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ──────────────────────────────────────────────────────────────────────────────
-- 7. report_flags policies
-- ──────────────────────────────────────────────────────────────────────────────

-- Users can read only the flags they submitted.
DROP POLICY IF EXISTS report_flags_select_own ON public.report_flags;
CREATE POLICY report_flags_select_own
  ON public.report_flags
  FOR SELECT
  TO authenticated
  USING (reporter_id = auth.uid());

-- Admin can read all flags for moderation.
DROP POLICY IF EXISTS report_flags_select_admin ON public.report_flags;
CREATE POLICY report_flags_select_admin
  ON public.report_flags
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- Authenticated users can insert flags.
-- reporter_id must match auth.uid().
-- Users cannot flag their own reports, but can flag any report owned by others.
-- Uses explicit outer column reference report_flags.report_id to avoid ambiguity.
DROP POLICY IF EXISTS report_flags_insert ON public.report_flags;
CREATE POLICY report_flags_insert
  ON public.report_flags
  FOR INSERT
  TO authenticated
  WITH CHECK (
    reporter_id = auth.uid()
    AND NOT EXISTS (
      SELECT 1 FROM public.reports r
      WHERE r.id = report_flags.report_id
        AND r.owner_id = auth.uid()
    )
  );

-- Only admin can update flags (change review_status).
DROP POLICY IF EXISTS report_flags_update_admin ON public.report_flags;
CREATE POLICY report_flags_update_admin
  ON public.report_flags
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ──────────────────────────────────────────────────────────────────────────────
-- 8. Admin moderation functions
--    These bypass column-level grant restrictions using SECURITY DEFINER,
--    but strictly verify admin role before making changes.
-- ──────────────────────────────────────────────────────────────────────────────

-- 8a. Admin: hide or show a report
CREATE OR REPLACE FUNCTION public.admin_set_report_moderation(
  p_report_id         uuid,
  p_moderation_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Verify caller is admin
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  -- Validate moderation_status value
  IF p_moderation_status NOT IN ('visible', 'hidden') THEN
    RAISE EXCEPTION 'Invalid moderation_status: %', p_moderation_status;
  END IF;

  UPDATE public.reports
  SET    moderation_status = p_moderation_status,
         updated_at = now()
  WHERE  id = p_report_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Report not found: %', p_report_id;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.admin_set_report_moderation(uuid, text) IS
  'Admin-only: set a report''s moderation_status to visible or hidden.';

REVOKE ALL ON FUNCTION public.admin_set_report_moderation(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_set_report_moderation(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_set_report_moderation(uuid, text) TO authenticated;

-- 8b. Admin: review a flag
CREATE OR REPLACE FUNCTION public.admin_review_flag(
  p_flag_id       uuid,
  p_review_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Verify caller is admin
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  -- Validate review_status value
  IF p_review_status NOT IN ('open', 'reviewed', 'dismissed') THEN
    RAISE EXCEPTION 'Invalid review_status: %', p_review_status;
  END IF;

  UPDATE public.report_flags
  SET    review_status = p_review_status
  WHERE  id = p_flag_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Flag not found: %', p_flag_id;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.admin_review_flag(uuid, text) IS
  'Admin-only: update a flag''s review_status.';

REVOKE ALL ON FUNCTION public.admin_review_flag(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_review_flag(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_review_flag(uuid, text) TO authenticated;
