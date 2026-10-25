# FoundIt — Project Starter Kit

**FoundIt — Lost & Found UNSRAT**  
*Lost Today, Found Tomorrow.*

This folder contains the planning and implementation rules for the FoundIt Android MVP, built with Flutter/Dart and Supabase Free.

## Source-of-truth files

- `md/PRD.md` — product scope, features, and acceptance criteria.
- `md/DATA_MODEL.md` — PostgreSQL tables, fixed values, access rules, contact lookup, and Storage decisions.
- `md/UI_UX_DESIGN.md` — modern visual system, navigation, ASCII wireframes, and UI states.
- `md/AGENTS.md` — persistent instructions for Antigravity.
- `md/DEVELOPMENT_ROADMAP.md` — milestone-by-milestone development and testing plan.
- `md/M2A_DATABASE_GUIDE.md` — database schema, RLS, and Storage specifications.
- `supabase/migrations/README.md` — notes for versioned SQL migrations.

## Current technical decisions

- Frontend: Flutter + Dart, developed in VS Code/Antigravity.
- Backend: Supabase Auth + PostgreSQL + Supabase Storage.
- Photo bucket: `report-photos`, intended for public report images, with upload/delete restricted by Storage policies.
- WhatsApp integration: `url_launcher` and an authenticated Supabase database function for contact lookup.
- Supabase credentials are supplied at run/build time with `SUPABASE_URL` and `SUPABASE_ANON_KEY`. If both are omitted, the app starts with in-memory mock services; supplying only one is a configuration error.
- Android password recovery redirects to `com.example.foundit://reset-password`. Add this exact URI to Supabase Auth's allowed redirect URLs. If the Android `applicationId` changes, update the URI in `SupabaseAuthService.passwordRecoveryRedirect`, the Android manifest intent filter, and Supabase Auth URL Configuration together.
- No Firebase, FlutterFlow, Cloudinary, paid services, internal chat, push notifications, GPS/maps, or AI image recognition in MVP.

Apply the versioned Supabase migrations before using the backend. The WhatsApp contact flow requires `20261025000000_reporter_whatsapp_rpc.sql` in addition to the schema, RLS, and Storage migrations. See `md/M2A_DATABASE_GUIDE.md` for the CLI workflow.

For Android password recovery, add `com.example.foundit://reset-password` under **Supabase Dashboard → Authentication → URL Configuration → Redirect URLs**. The email link opens the app, where the user enters and confirms a new password. This URI uses the current Android application ID and must be updated in the Android manifest, `SupabaseAuthService.passwordRecoveryRedirect`, and Supabase Auth settings together if that ID changes.

## Recommended start order

1. Create the Flutter project with `flutter create foundit`.
2. Copy these files into the project root.
3. Open that folder in Antigravity.
4. Ask Antigravity to read the documents and inspect the environment without changing code.
5. Verify the Flutter starter app runs on Android and commit the baseline with Git.
6. Implement M1 screens with mock data before connecting Supabase.
7. Create and test the SQL migration/RLS policies before connecting real data.

## Important security notes

- Never include a Supabase `service_role`/secret key in client-side Flutter code.
- The publishable/anon key is intended for client applications, but is safe only when grants, RLS, and Storage policies are configured correctly.
- Public bucket photos can be viewed by anyone with the URL. Do not upload personal documents, identity/card numbers, bank details, or private images.
- Do not disable RLS to make the app work.
- The Free tier has quotas and may pause inactive projects. Review the current Supabase dashboard and usage before a demo.

## Documents are not migrations

`md/DATA_MODEL.md` is the schema specification. Versioned migrations have been prepared under `supabase/migrations/` and should be reviewed prior to CLI deployment.
