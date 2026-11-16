ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_notification_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_notification_type_check
  CHECK (
    notification_type IN (
      'new_report',
      'report_status',
      'matching_report',
      'admin_update'
    )
  );

CREATE OR REPLACE FUNCTION public.notify_new_report()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.status <> 'active' OR NEW.moderation_status <> 'visible' THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (
    user_id, notification_type, title, body, report_id
  )
  SELECT
    profiles.id,
    'new_report',
    'Laporan baru ditambahkan',
    left(
      'Laporan "' || NEW.item_name || '" baru ditambahkan di ' ||
        NEW.campus_area || '.',
      300
    ),
    NEW.id
  FROM public.profiles AS profiles
  WHERE profiles.id <> NEW.owner_id;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.notify_new_report() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS reports_notify_new_report ON public.reports;
CREATE TRIGGER reports_notify_new_report
  AFTER INSERT ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_report();
