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

  IF auth.uid() = NEW.owner_id THEN
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
    left(
      'Status laporan "' || NEW.item_name || '" sekarang ' ||
        v_status_label || '.',
      300
    ),
    NEW.id
  );
  RETURN NEW;
END;
$$;
