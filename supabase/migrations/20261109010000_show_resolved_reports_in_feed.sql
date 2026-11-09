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
WHERE r.moderation_status = 'visible';

COMMENT ON VIEW public.public_reports IS
  'Public feed of active and resolved reports allowed by moderation. '
  'No owner_id, no moderation_status, no contact info.';
