-- Allow authenticated users to update their own WhatsApp number.
--
-- Column-level GRANT limits update permission strictly to whatsapp_number.
-- RLS policy `user_contacts_update_own` restricts updates strictly to rows where user_id = auth.uid().
-- CHECK constraint `CHECK (whatsapp_number IS NULL OR whatsapp_number ~ '^\d{10,15}$')` validates format.
-- Existing allow_whatsapp_contact preference is preserved.

GRANT UPDATE (whatsapp_number) ON public.user_contacts TO authenticated;

COMMENT ON COLUMN public.user_contacts.whatsapp_number IS
  'Normalized international digits, e.g. 6281234567890. Editable by row owner.';
