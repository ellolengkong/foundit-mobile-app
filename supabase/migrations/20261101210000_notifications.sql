CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type text NOT NULL
    CHECK (notification_type IN ('report_status', 'matching_report', 'admin_update')),
  title text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 100),
  body text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 300),
  report_id uuid REFERENCES public.reports(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  read_at timestamptz
);

CREATE INDEX notifications_user_created_idx
  ON public.notifications (user_id, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.notifications FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.notifications TO authenticated;
GRANT UPDATE (read_at) ON public.notifications TO authenticated;

CREATE POLICY notifications_select_own
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY notifications_update_own
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE OR REPLACE FUNCTION public.notify_report_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status_label text;
BEGIN
  IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NEW;
  END IF;

  v_status_label := CASE NEW.status
    WHEN 'resolved' THEN 'selesai'
    ELSE 'aktif kembali'
  END;

  INSERT INTO public.notifications (
    user_id, notification_type, title, body, report_id
  )
  VALUES (
    NEW.owner_id,
    'report_status',
    'Status laporan berubah',
    left('Status laporan "' || NEW.item_name || '" sekarang ' || v_status_label || '.', 300),
    NEW.id
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_report_moderation_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_moderation_label text;
BEGIN
  IF OLD.moderation_status IS NOT DISTINCT FROM NEW.moderation_status THEN
    RETURN NEW;
  END IF;

  v_moderation_label := CASE NEW.moderation_status
    WHEN 'hidden' THEN 'disembunyikan oleh admin'
    ELSE 'ditampilkan kembali oleh admin'
  END;

  INSERT INTO public.notifications (
    user_id, notification_type, title, body, report_id
  )
  VALUES (
    NEW.owner_id,
    'admin_update',
    'Pembaruan dari admin',
    left('Laporan "' || NEW.item_name || '" ' || v_moderation_label || '.', 300),
    NEW.id
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_matching_reports()
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
  SELECT DISTINCT
    existing.owner_id,
    'matching_report',
    'Laporan yang mungkin cocok',
    left('Ada laporan baru "' || NEW.item_name || '" di ' || NEW.campus_area ||
      ' yang mungkin cocok dengan laporan Anda.', 300),
    NEW.id
  FROM public.reports AS existing
  WHERE existing.owner_id <> NEW.owner_id
    AND existing.report_type <> NEW.report_type
    AND existing.category = NEW.category
    AND existing.campus_area = NEW.campus_area
    AND existing.status = 'active'
    AND existing.moderation_status = 'visible';

  INSERT INTO public.notifications (
    user_id, notification_type, title, body, report_id
  )
  SELECT
    NEW.owner_id,
    'matching_report',
    'Laporan yang mungkin cocok',
    left('Laporan "' || existing.item_name || '" di ' || existing.campus_area ||
      ' mungkin cocok dengan laporan baru Anda.', 300),
    existing.id
  FROM (
    SELECT DISTINCT ON (matched.owner_id)
      matched.owner_id,
      matched.id,
      matched.item_name,
      matched.campus_area
    FROM public.reports AS matched
    WHERE matched.owner_id <> NEW.owner_id
      AND matched.report_type <> NEW.report_type
      AND matched.category = NEW.category
      AND matched.campus_area = NEW.campus_area
      AND matched.status = 'active'
      AND matched.moderation_status = 'visible'
    ORDER BY matched.owner_id, matched.created_at DESC
  ) AS existing;

  RETURN NEW;
END;
$$;

CREATE TRIGGER reports_notify_status_change
  AFTER UPDATE OF status ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_report_status_change();

CREATE TRIGGER reports_notify_moderation_change
  AFTER UPDATE OF moderation_status ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_report_moderation_change();

CREATE TRIGGER reports_notify_matching_reports
  AFTER INSERT ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_matching_reports();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END;
$$;
