# Supabase migrations

Store versioned SQL migrations in this directory.

The first migration has **not** been generated yet. Before writing it, follow `../DATA_MODEL.md` and implement/test all of the following together:

- `profiles`, `user_contacts`, `reports`, and `report_flags` tables with constraints/indexes/triggers;
- the safe `public_reports` view;
- profile creation on Auth sign-up (always role `user`);
- RLS policies and least-privilege grants;
- admin helper/RPCs that verify the admin role;
- authenticated WhatsApp-contact lookup with opt-in validation;
- `report-photos` Storage bucket and owner-scoped upload/update/delete policies.

Do not put a Supabase service-role/secret key in SQL files or Flutter code. Test unauthorized actions before connecting the application.
