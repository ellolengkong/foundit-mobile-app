CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_whatsapp_number text;
  v_allow_whatsapp_contact boolean;
BEGIN
  v_whatsapp_number := regexp_replace(
    coalesce(NEW.raw_user_meta_data ->> 'whatsapp_number', ''),
    '[^0-9]',
    '',
    'g'
  );

  IF left(v_whatsapp_number, 1) = '0' THEN
    v_whatsapp_number := '62' || substr(v_whatsapp_number, 2);
  END IF;

  IF char_length(v_whatsapp_number) NOT BETWEEN 10 AND 15 THEN
    RAISE EXCEPTION 'Nomor WhatsApp wajib diisi dengan 10-15 digit yang valid.'
      USING ERRCODE = '23514';
  END IF;

  v_allow_whatsapp_contact :=
    lower(coalesce(NEW.raw_user_meta_data ->> 'allow_whatsapp_contact', 'false'))
    = 'true';

  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    coalesce(nullif(trim(NEW.raw_user_meta_data ->> 'full_name'), ''), 'Pengguna Baru'),
    'user'
  );

  INSERT INTO public.user_contacts (
    user_id,
    whatsapp_number,
    allow_whatsapp_contact
  )
  VALUES (
    NEW.id,
    v_whatsapp_number,
    v_allow_whatsapp_contact
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS
  'Creates a user profile and saves the required signup WhatsApp number as a private contact row.';

COMMENT ON TABLE public.user_contacts IS
  'Private contact record created on registration; nullable WhatsApp numbers remain for legacy accounts.';

REVOKE INSERT (whatsapp_number) ON public.user_contacts FROM authenticated;
REVOKE UPDATE (whatsapp_number) ON public.user_contacts FROM authenticated;
