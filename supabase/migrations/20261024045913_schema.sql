-- ============================================================================
-- FoundIt M2A — Migration: Schema
-- Tables, constraints, indexes, triggers, helper functions, and view.
-- Based on DATA_MODEL.md v1.1
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────────
-- 1. Generic updated_at trigger function
--    Must be created before tables that attach it as a trigger.
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_updated_at() IS
  'Sets updated_at to now() before any UPDATE. Attached to tables that track modification time.';

-- Revoke execute from application roles (only PostgreSQL system triggers invoke this)
REVOKE ALL ON FUNCTION public.handle_updated_at() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_updated_at() FROM anon;
REVOKE ALL ON FUNCTION public.handle_updated_at() FROM authenticated;

-- ──────────────────────────────────────────────────────────────────────────────
-- 2. profiles table  (DATA_MODEL.md §4.1)
--    Public-app profile and role — one row per Supabase Auth user.
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id          uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   text        NOT NULL
                          CONSTRAINT profiles_full_name_length CHECK (char_length(full_name) BETWEEN 2 AND 80),
  role        text        NOT NULL DEFAULT 'user'
                          CONSTRAINT profiles_role_check CHECK (role IN ('user', 'admin')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.profiles IS 'Public-app profile and role — one row per Supabase Auth user.';
COMMENT ON COLUMN public.profiles.role IS 'user or admin; always defaults to user. Only trusted SQL/Dashboard can set admin.';

DROP TRIGGER IF EXISTS profiles_updated_at ON public.profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ──────────────────────────────────────────────────────────────────────────────
-- 3. Helper function: is_admin()
--    Defined after public.profiles exists.
--    Uses public.profiles.role as the single authoritative source of truth.
--    Never relies on client user_metadata.
--    SECURITY DEFINER with empty search_path to prevent hijacking and avoid RLS recursion.
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_role text;
BEGIN
  -- Unauthenticated callers are never admin
  IF auth.uid() IS NULL THEN
    RETURN false;
  END IF;

  -- Authoritative database lookup in public.profiles (runs as definer with BYPASSRLS)
  SELECT p.role INTO v_role
  FROM public.profiles p
  WHERE p.id = auth.uid();

  RETURN coalesce(v_role = 'admin', false);
END;
$$;

COMMENT ON FUNCTION public.is_admin() IS
  'Returns true if the authenticated user has role=admin in public.profiles. '
  'Uses public.profiles.role as the single source of truth.';

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_admin() FROM anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ──────────────────────────────────────────────────────────────────────────────
-- 4. Profile-on-signup trigger  (DATA_MODEL.md §4.1 / §10)
--    Always sets role = ''user'', regardless of any user-supplied metadata.
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    coalesce(nullif(trim(NEW.raw_user_meta_data ->> 'full_name'), ''), 'Pengguna Baru'),
    'user'
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS
  'Creates a profiles row with role=user on Auth signup. Ignores any user-supplied role metadata.';

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM anon;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM authenticated;

-- ──────────────────────────────────────────────────────────────────────────────
-- 5. user_contacts table  (DATA_MODEL.md §4.2)
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_contacts (
  user_id                uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  whatsapp_number        text
                         CONSTRAINT user_contacts_whatsapp_format
                           CHECK (whatsapp_number IS NULL OR whatsapp_number ~ '^\d{10,15}$'),
  allow_whatsapp_contact boolean     NOT NULL DEFAULT false,
  updated_at             timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.user_contacts IS 'Private contact preference — one optional row per user.';
COMMENT ON COLUMN public.user_contacts.whatsapp_number IS 'Normalized international digits, e.g. 6281234567890.';
COMMENT ON COLUMN public.user_contacts.allow_whatsapp_contact IS 'Explicit opt-in to be contacted about reports.';

DROP TRIGGER IF EXISTS user_contacts_updated_at ON public.user_contacts;
CREATE TRIGGER user_contacts_updated_at
  BEFORE UPDATE ON public.user_contacts
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ──────────────────────────────────────────────────────────────────────────────
-- 6. reports table  (DATA_MODEL.md §4.3)
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reports (
  id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id           uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
                                 DEFAULT auth.uid(),
  report_type        text        NOT NULL
                                 CONSTRAINT reports_type_check
                                   CHECK (report_type IN ('lost', 'found')),
  item_name          text        NOT NULL
                                 CONSTRAINT reports_item_name_length
                                   CHECK (char_length(item_name) BETWEEN 1 AND 100),
  category           text        NOT NULL
                                 CONSTRAINT reports_category_check
                                   CHECK (category IN (
                                     'electronics_gadgets',
                                     'wallet_money',
                                     'cards_documents',
                                     'keys_access',
                                     'bags_pouches',
                                     'books_stationery',
                                     'clothing_equipment',
                                     'personal_accessories',
                                     'bottles_food_containers',
                                     'other'
                                   )),
  description        text
                                 CONSTRAINT reports_description_length
                                   CHECK (description IS NULL OR char_length(description) <= 500),
  photo_path         text,
  campus_area        text        NOT NULL,
  building_name      text,
  specific_location  text,
  event_date         date        NOT NULL,
  status             text        NOT NULL DEFAULT 'active'
                                 CONSTRAINT reports_status_check
                                   CHECK (status IN ('active', 'resolved')),
  moderation_status  text        NOT NULL DEFAULT 'visible'
                                 CONSTRAINT reports_moderation_check
                                   CHECK (moderation_status IN ('visible', 'hidden')),
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.reports IS 'Lost/found reports. One row = one report.';
COMMENT ON COLUMN public.reports.owner_id IS 'FK to auth.users.id; immutable to the client.';
COMMENT ON COLUMN public.reports.photo_path IS 'Bucket-relative Storage path, fixed as {report_id}/photo without extension. Never includes owner ID, bucket name prefix, or full URL.';
COMMENT ON COLUMN public.reports.status IS 'active = still searching; resolved = owner considers it done.';
COMMENT ON COLUMN public.reports.moderation_status IS 'visible = may appear publicly; hidden = hidden by admin.';

DROP TRIGGER IF EXISTS reports_updated_at ON public.reports;
CREATE TRIGGER reports_updated_at
  BEFORE UPDATE ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ──────────────────────────────────────────────────────────────────────────────
-- 7. report_flags table  (DATA_MODEL.md §4.4)
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.report_flags (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id      uuid        NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  reporter_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason         text        NOT NULL
                              CONSTRAINT report_flags_reason_check
                                CHECK (reason IN (
                                  'spam',
                                  'false_information',
                                  'inappropriate',
                                  'personal_data',
                                  'other'
                                )),
  details        text
                              CONSTRAINT report_flags_details_length
                                CHECK (details IS NULL OR char_length(details) <= 300),
  review_status  text        NOT NULL DEFAULT 'open'
                              CONSTRAINT report_flags_review_check
                                CHECK (review_status IN ('open', 'reviewed', 'dismissed')),
  created_at     timestamptz NOT NULL DEFAULT now(),

  -- One flag per user per report
  CONSTRAINT report_flags_unique_per_user UNIQUE (report_id, reporter_id)
);

COMMENT ON TABLE  public.report_flags IS 'Report-abuse flags submitted by users.';
COMMENT ON COLUMN public.report_flags.reporter_id IS 'FK to auth.users.id; must equal auth.uid() at insertion.';
COMMENT ON COLUMN public.report_flags.review_status IS 'open, reviewed, or dismissed. Only admin changes this.';

-- ──────────────────────────────────────────────────────────────────────────────
-- 8. Indexes  (DATA_MODEL.md §9)
-- ──────────────────────────────────────────────────────────────────────────────

-- Feed: active + visible reports, newest first
CREATE INDEX IF NOT EXISTS idx_reports_feed
  ON public.reports (status, moderation_status, created_at DESC);

-- Type/category filters
CREATE INDEX IF NOT EXISTS idx_reports_type_category
  ON public.reports (report_type, category, status);

-- Location filters
CREATE INDEX IF NOT EXISTS idx_reports_location
  ON public.reports (campus_area, building_name);

-- My Reports: owner's reports, newest first
CREATE INDEX IF NOT EXISTS idx_reports_owner
  ON public.reports (owner_id, created_at DESC);

-- Flag moderation
CREATE INDEX IF NOT EXISTS idx_report_flags_moderation
  ON public.report_flags (report_id, review_status);

-- ──────────────────────────────────────────────────────────────────────────────
-- 9. public_reports view  (DATA_MODEL.md §4.3 / §8)
--    Only safe public fields; hard-filters active + visible.
--    Does NOT expose owner_id, moderation_status, or contact details.
--    Uses security_barrier = true to prevent side-channel pushdown leaks.
--    security_invoker remains false (default) so base table reports can keep
--    owner_id fully private without granting direct SELECT on foreign rows.
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.public_reports
WITH (security_barrier = true) AS
SELECT
  r.id,
  r.report_type,
  r.item_name,
  r.category,
  r.description,
  r.photo_path,
  r.campus_area,
  r.building_name,
  r.specific_location,
  r.event_date,
  r.status,
  r.created_at,
  r.updated_at
FROM public.reports r
WHERE r.status = 'active'
  AND r.moderation_status = 'visible';

COMMENT ON VIEW public.public_reports IS
  'Read-only public feed: only active+visible reports with safe columns. '
  'No owner_id, no moderation_status, no contact info.';

-- ──────────────────────────────────────────────────────────────────────────────
-- 10. get_reporter_whatsapp_for_report(report_id)  (DATA_MODEL.md §4.2)
--     Returns the WhatsApp number ONLY when ALL conditions hold:
--       1. Caller is authenticated
--       2. Report exists, is active, and is visible
--       3. Caller is NOT the report owner
--       4. Report owner has a whatsapp_number AND allow_whatsapp_contact = true
--     Uses SECURITY DEFINER to read user_contacts without granting direct SELECT.
-- ──────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_reporter_whatsapp_for_report(p_report_id uuid)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id uuid;
  v_owner_id  uuid;
  v_number    text;
BEGIN
  -- 1. Must be authenticated
  v_caller_id := auth.uid();
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- 2. Report must exist, be active, and be visible
  SELECT r.owner_id
  INTO   v_owner_id
  FROM   public.reports r
  WHERE  r.id = p_report_id
    AND  r.status = 'active'
    AND  r.moderation_status = 'visible';

  IF v_owner_id IS NULL THEN
    RETURN NULL;  -- Report not found or not active/visible
  END IF;

  -- 3. Caller must NOT be the report owner
  IF v_caller_id = v_owner_id THEN
    RETURN NULL;
  END IF;

  -- 4. Owner must have opted in and provided a number
  SELECT uc.whatsapp_number
  INTO   v_number
  FROM   public.user_contacts uc
  WHERE  uc.user_id = v_owner_id
    AND  uc.allow_whatsapp_contact = true
    AND  uc.whatsapp_number IS NOT NULL;

  RETURN v_number;  -- NULL if owner has not opted in or has no number
END;
$$;

COMMENT ON FUNCTION public.get_reporter_whatsapp_for_report(uuid) IS
  'Returns the report owner''s WhatsApp number if caller is authenticated, '
  'report is active+visible, caller is not the owner, and owner opted in. '
  'SECURITY DEFINER with strict authorization checks.';

-- Restrict execution to authenticated users only
REVOKE ALL ON FUNCTION public.get_reporter_whatsapp_for_report(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_reporter_whatsapp_for_report(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_reporter_whatsapp_for_report(uuid) TO authenticated;
