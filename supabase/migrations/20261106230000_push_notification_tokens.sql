CREATE TABLE public.push_device_tokens (
  token text PRIMARY KEY
    CHECK (char_length(token) BETWEEN 1 AND 4096),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  platform text NOT NULL CHECK (platform IN ('android', 'ios')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX push_device_tokens_user_idx
  ON public.push_device_tokens (user_id);

ALTER TABLE public.push_device_tokens ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.push_device_tokens FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.register_push_device_token(
  p_token text,
  p_platform text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication is required.'
      USING ERRCODE = '28000';
  END IF;
  IF p_token IS NULL OR char_length(p_token) NOT BETWEEN 1 AND 4096 THEN
    RAISE EXCEPTION 'Invalid push token.'
      USING ERRCODE = '22023';
  END IF;
  IF p_platform NOT IN ('android', 'ios') THEN
    RAISE EXCEPTION 'Unsupported push platform.'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.push_device_tokens (token, user_id, platform)
  VALUES (p_token, v_user_id, p_platform)
  ON CONFLICT (token) DO UPDATE
    SET user_id = EXCLUDED.user_id,
        platform = EXCLUDED.platform,
        updated_at = now();
END;
$$;

REVOKE ALL ON FUNCTION public.register_push_device_token(text, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.register_push_device_token(text, text)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.unregister_push_device_token(p_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required.'
      USING ERRCODE = '28000';
  END IF;

  DELETE FROM public.push_device_tokens
  WHERE token = p_token
    AND user_id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.unregister_push_device_token(text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.unregister_push_device_token(text)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.set_push_device_token_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER push_device_tokens_updated_at
  BEFORE UPDATE ON public.push_device_tokens
  FOR EACH ROW
  EXECUTE FUNCTION public.set_push_device_token_updated_at();
