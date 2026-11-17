-- Restore active-only filter on public_reports view.
-- Resolved reports remain safely stored in the base reports table,
-- accessible to owners via getUserReports and to admins via allReports,
-- but are excluded from the public feed, search, and filters.

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
