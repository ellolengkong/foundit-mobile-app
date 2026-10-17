# Antigravity Workspace Instructions — FoundIt

You are helping build FoundIt, an Android Lost & Found app for UNSRAT. Read `PRD.md`, `DATA_MODEL.md`, `UI_UX_DESIGN.md`, and `DEVELOPMENT_ROADMAP.md` before changing files. These files are the product source of truth.

## Decisions that must not drift

- Use Flutter + Dart in VS Code/Antigravity. Do not use FlutterFlow.
- Backend is **Supabase only**: Supabase Auth, PostgreSQL, and Supabase Storage Free. Do not add Firebase, Cloudinary, or another backend unless the project owner explicitly changes this decision.
- Build for Android first.
- Main navigation: Beranda, centered `+` Lapor action, Profil.
- Guests can browse/search/view reports; authentication is required to create/manage reports or use the WhatsApp contact action.
- Use table/column names, enums, categories, status values, and matching weights from `DATA_MODEL.md` and `PRD.md` exactly.
- Use design tokens and typography from `UI_UX_DESIGN.md` (Soft Indigo, Plus Jakarta Sans).
- Do not introduce paid services, push notifications, chat, GPS/maps, AI image matching, or external full-text search in the MVP.
- Keep photo upload optional and compatible with Supabase Free quota limits.

## How to work

1. Work on exactly one milestone/feature per task. Do not generate the entire app in one pass.
2. Before editing, inspect the current project and produce a short plan: files to create/change, behavior, and test method.
3. Ask before destructive changes, broad refactors, adding paid services, or changing product/schema decisions.
4. Prefer the smallest implementation that satisfies the PRD. Keep dependencies minimal and explain each new package.
5. Never rename tables/columns, change role/status semantics, or alter matching weights without proposing a documentation update first.
6. Include loading, empty, error, success, validation, and retry states as relevant.
7. After changes, run `dart format .`, `flutter analyze`, and relevant `flutter test` commands. Report real outputs and do not claim a check passed if it was not run.
8. Keep diffs reviewable; suggest a Git commit after a milestone passes.
9. Explain non-trivial code in beginner-friendly terms and give manual test instructions.
10. Never place credentials in source code or paste secrets into prompts/logs. Use the Supabase project URL and publishable/anon key in the client; never use `service_role` or secret keys in Flutter.

## Security requirements

- RLS must be enabled for exposed tables. Grants and policies must both be reviewed.
- Guests read report fields only through the restricted `public_reports` view.
- `user_contacts` is private. Do not select other users' contact rows from the Flutter app. Use the documented authenticated RPC that checks report status and contact opt-in.
- Users cannot set their own role to `admin`, change `owner_id`, change moderation status, or alter flag review status through normal client table updates.
- Do not disable RLS or use permissive policies just to make a demo work.
- The `report-photos` bucket is public media: never upload sensitive IDs, bank-card details, or private documents. Restrict upload/replace operations to the authenticated owner's path. Deletion is allowed to the owner and, through a role-checked admin policy, to admins when moderation requires removing a sensitive image.
- Admin role assignment and moderation must be done by trusted SQL/RPC operations.

## Package policy

Add packages only when needed. Expected candidates:

- `supabase_flutter`: Supabase Auth, database, and Storage client.
- `url_launcher`: open WhatsApp.
- `image_picker`: select optional report photo.
- `google_fonts` only if the Plus Jakarta Sans font is not bundled locally; prefer a bundled font for predictable offline rendering.
- `intl` only if date formatting needs it.

Do not install all candidates blindly. Check current package compatibility and add one at a time.

## Milestones

- M0: verify environment, create Flutter skeleton, run on Android, and initialize Git.
- M1: theme, app shell, three-part navigation, screens with mock data.
- M2: Supabase SQL migration, RLS, public view, contact/admin functions, Storage bucket policies; test before UI data integration.
- M3: authentication, guest routing, sign-up/login/reset/logout.
- M4: report CRUD and optional photo upload.
- M5: public feed, details, search, filters, My Reports.
- M6: deterministic rule-based matching plus tests.
- M7: opted-in WhatsApp contact, report flags, admin moderation.
- M8: security/functional QA, UI polish, and release APK.

Never move to the next milestone until the current milestone's acceptance checks pass.
