-- ============================================================================
-- FoundIt M2A — Migration: Storage Bucket & Policies
-- Configures the report-photos bucket and its access policies.
-- Fixed single photo convention: {report_id}/photo (no extension).
-- Based on DATA_MODEL.md §7
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────────
-- 1. Create the report-photos bucket
--    Public bucket: anyone with the public asset URL can retrieve photos.
--    Allowed MIME: image/jpeg, image/png, image/webp (enforced by Storage engine)
--    Max file size: ~1 MB (1048576 bytes)
-- ──────────────────────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'report-photos',
  'report-photos',
  true,
  1048576,  -- 1 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ──────────────────────────────────────────────────────────────────────────────
-- 2. Storage RLS policies
--    Object path convention: {report_id}/photo (exact fixed name, no extension, no subfolders).
--    One report = exactly one photo object.
--    storage.foldername(name)[1] corresponds to the report_id folder.
--    name must equal (storage.foldername(name))[1] || '/photo' (rejects subfolders & alternate names).
--    Policies verify actual report ownership against public.reports (owner_id = auth.uid()).
-- ──────────────────────────────────────────────────────────────────────────────

-- 2a. Owner-scoped SELECT: authenticated users can only query/list objects
--     for reports they actually own, with exact path {report_id}/photo.
--     (Bucket remains public so direct asset retrieval via URL works without querying storage.objects).
DROP POLICY IF EXISTS storage_report_photos_select ON storage.objects;
DROP POLICY IF EXISTS storage_report_photos_select_own ON storage.objects;
CREATE POLICY storage_report_photos_select_own
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'report-photos'
    AND name = (storage.foldername(name))[1] || '/photo'
    AND EXISTS (
      SELECT 1 FROM public.reports r
      WHERE r.id::text = (storage.foldername(name))[1]
        AND r.owner_id = auth.uid()
    )
  );

-- 2b. Authenticated owner can upload (INSERT) only after creating the report.
--     Verifies that the folder matches an existing report owned by auth.uid(),
--     and that the object filename is exactly 'photo' without subfolders or alternate names.
DROP POLICY IF EXISTS storage_report_photos_insert ON storage.objects;
CREATE POLICY storage_report_photos_insert
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'report-photos'
    AND name = (storage.foldername(name))[1] || '/photo'
    AND EXISTS (
      SELECT 1 FROM public.reports r
      WHERE r.id::text = (storage.foldername(name))[1]
        AND r.owner_id = auth.uid()
    )
  );

-- 2c. Authenticated owner can replace/overwrite (UPDATE) only their own report's photo.
DROP POLICY IF EXISTS storage_report_photos_update ON storage.objects;
CREATE POLICY storage_report_photos_update
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'report-photos'
    AND name = (storage.foldername(name))[1] || '/photo'
    AND EXISTS (
      SELECT 1 FROM public.reports r
      WHERE r.id::text = (storage.foldername(name))[1]
        AND r.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    bucket_id = 'report-photos'
    AND name = (storage.foldername(name))[1] || '/photo'
    AND EXISTS (
      SELECT 1 FROM public.reports r
      WHERE r.id::text = (storage.foldername(name))[1]
        AND r.owner_id = auth.uid()
    )
  );

-- 2d. Authenticated owner can delete the photo belonging to their own report.
DROP POLICY IF EXISTS storage_report_photos_delete_own ON storage.objects;
CREATE POLICY storage_report_photos_delete_own
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'report-photos'
    AND name = (storage.foldername(name))[1] || '/photo'
    AND EXISTS (
      SELECT 1 FROM public.reports r
      WHERE r.id::text = (storage.foldername(name))[1]
        AND r.owner_id = auth.uid()
    )
  );

-- 2e. Admin can delete any photo in the bucket (for moderation).
--     Uses the is_admin() helper to verify role.
DROP POLICY IF EXISTS storage_report_photos_delete_admin ON storage.objects;
CREATE POLICY storage_report_photos_delete_admin
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'report-photos'
    AND public.is_admin()
  );
