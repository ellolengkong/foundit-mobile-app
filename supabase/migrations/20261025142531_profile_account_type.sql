ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS account_type text NOT NULL DEFAULT 'student'
  CONSTRAINT profiles_account_type_check
  CHECK (account_type IN ('student', 'lecturer'));

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_whatsapp_number text;
  v_account_type text;
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

  v_account_type := coalesce(
    nullif(NEW.raw_user_meta_data ->> 'account_type', ''),
    'student'
  );

  IF v_account_type NOT IN ('student', 'lecturer') THEN
    RAISE EXCEPTION 'Jenis pengguna tidak valid.'
      USING ERRCODE = '23514';
  END IF;

  v_allow_whatsapp_contact :=
    lower(coalesce(NEW.raw_user_meta_data ->> 'allow_whatsapp_contact', 'false'))
    = 'true';

  INSERT INTO public.profiles (id, full_name, role, account_type)
  VALUES (
    NEW.id,
    coalesce(nullif(trim(NEW.raw_user_meta_data ->> 'full_name'), ''), 'Pengguna Baru'),
    'user',
    v_account_type
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

COMMENT ON COLUMN public.profiles.account_type IS
  'Informational member type selected at signup: student or lecturer. Separate from the admin authorization role.';

COMMENT ON FUNCTION public.handle_new_user() IS
  'Creates a user profile and private contact row from validated signup metadata. Account type never changes the authorization role.';
