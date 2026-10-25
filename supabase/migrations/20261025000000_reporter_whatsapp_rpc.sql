-- Return a reporter's contact only for an authenticated, eligible request.
CREATE OR REPLACE FUNCTION public.get_reporter_whatsapp_for_report(
  p_report_id uuid
)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_whatsapp_number text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required.'
      USING ERRCODE = '42501';
  END IF;

  SELECT c.whatsapp_number
    INTO v_whatsapp_number
    FROM public.reports r
    JOIN public.user_contacts c ON c.user_id = r.owner_id
   WHERE r.id = p_report_id
     AND r.owner_id <> auth.uid()
     AND r.status = 'active'
     AND r.moderation_status = 'visible'
     AND c.allow_whatsapp_contact
     AND c.whatsapp_number IS NOT NULL;

  IF v_whatsapp_number IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN v_whatsapp_number;
END;
$$;

COMMENT ON FUNCTION public.get_reporter_whatsapp_for_report(uuid) IS
  'Returns an opted-in reporter WhatsApp number only to authenticated users for another owner’s active, visible report.';

REVOKE ALL ON FUNCTION public.get_reporter_whatsapp_for_report(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_reporter_whatsapp_for_report(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_reporter_whatsapp_for_report(uuid) TO authenticated;
