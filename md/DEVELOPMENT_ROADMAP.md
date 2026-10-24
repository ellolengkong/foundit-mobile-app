# FoundIt — Development Roadmap

This roadmap assumes Flutter + Supabase Free only. Do not use FlutterFlow or Firebase. Do not intentionally upgrade to a paid plan.

## Ground rules

- Build one feature at a time with Antigravity.
- Read `AGENTS.md`, `PRD.md`, `DATA_MODEL.md`, and `UI_UX_DESIGN.md` first.
- Review the plan and diff before accepting broad changes.
- Run the app after meaningful UI changes and keep a working Git commit for each milestone.
- Never place a Supabase `service_role`/secret key in the Flutter client.
- Public report photos are intentionally public; do not upload sensitive images.

## M0 — Environment and repository

1. Check Git, Flutter SDK, Dart, Android Studio/Android SDK, emulator or physical device, and Antigravity/VS Code extensions.
2. Run `flutter --version`, `dart --version`, `flutter doctor -v`, and `git --version`.
3. Resolve blocking Android toolchain issues reported by `flutter doctor`.
4. Create a Flutter project using `flutter create foundit` and open its folder in Antigravity.
5. Copy the project documents into the root: `PRD.md`, `DATA_MODEL.md`, `UI_UX_DESIGN.md`, `AGENTS.md`, `DEVELOPMENT_ROADMAP.md`, and `README.md`.
6. Initialize Git and commit the untouched Flutter skeleton.
7. Run the starter Flutter app on an Android emulator or physical device.

**Pass condition:** starter app runs on Android and the baseline Git commit exists.

## M1 — UI shell with mock data

- Implement the FoundIt theme, color tokens, typography, reusable components, and three-part navigation.
- Create Home, Report Search/Filter, Report Detail, Create Report, Login, Sign-up, Forgot Password, Profile/My Reports, Possible Matches, and simple Admin screens.
- Use mock data only; do not connect Supabase yet.
- Include empty/loading/error/success state designs and form validation.

**Pass condition:** all screens open and navigate correctly; no layout overflow on the target Android device; visual design follows `UI_UX_DESIGN.md`.

## M2 — Supabase schema, RLS, and Storage

1. Create a Supabase Free project.
2. Create a migration file under `supabase/migrations/` based on `DATA_MODEL.md`; do not make schema changes only in the Dashboard without recording them.
3. Create `profiles`, `user_contacts`, `reports`, and `report_flags` with checks, foreign keys, indexes, and `updated_at` triggers.
4. Create a profile-on-signup trigger that always assigns role `user`, ignoring role metadata submitted during sign-up.
5. Create the restricted `public_reports` view and grant only the intended roles access to it. Apply least-privilege column grants to base tables.
6. Create and test an `is_admin()` helper or equivalent secure admin check; implement admin-only moderation RPCs if used.
7. Implement the authenticated `get_reporter_whatsapp_for_report(report_id)` function. It must check authentication, report visibility/status, not-self contact, and reporter opt-in.
8. Create Supabase Storage bucket `report-photos`, public for intentionally public report images, restricted to JPEG/PNG/WebP and about 1 MB per object. Add Storage RLS policies so only authenticated owners can upload/replace objects in their report folder (`{report_id}/photo`); allow an admin to delete an object only through a role-checked admin policy for moderation.
9. Verify public media limitations: anyone with a valid photo URL can read it, so do not upload private documents or sensitive IDs.
10. Test table/view/function/Storage access with guest (`anon`), user A, user B, and admin.

**Pass condition:** migration runs cleanly and unauthorized data/Storage access is denied; public guest queries only return safe active/visible report fields.

## M3 — Authentication

- Add `supabase_flutter` and initialize it using project URL plus publishable/anon key.
- Implement sign-up, login, logout, password reset, auth-state handling, and validation.
- Create/read the `profiles` row using the database trigger.
- Keep guest browsing available.
- If a guest presses Lapor, route to login/sign-up and continue to the form after success.
- Ensure registration cannot set an admin role.

**Pass condition:** auth flows work; guests can browse; report actions require a signed-in account.

## M4 — Report CRUD and optional photo

- Implement create/edit/delete own report and `active`/`resolved` status behavior.
- Let the database set `owner_id` from authenticated identity; never trust an owner ID supplied by the client.
- Validate report fields and location choices.
- Upload one optional compressed image to `report-photos` using an owner-scoped path. Save only `photo_path` in PostgreSQL.
- If image upload fails, allow the report to exist without the image and explain this to the user.
- Replace/delete old Storage objects through Supabase Storage API; do not edit the `storage` schema directly.

**Pass condition:** users can create/edit/resolve/delete only their own reports; user B cannot change user A's report; photo policies are verified.

## M5 — Feed, detail, search, filters

- Fetch public feed/detail data from the `public_reports` view.
- Implement keyword search and filters: report type, category, campus area, building/facility, and date.
- Implement My Reports using the authenticated reports query and RLS.
- Ensure loading, no-results, failed-network, and retry states are clear.

**Pass condition:** public feed excludes resolved/hidden reports; test data returns expected filter/search results.

## M6 — Rule-based matching

- Implement a deterministic pure-Dart scoring function with unit tests.
- Compare only opposite report types and active/visible candidates.
- Use category (30), keyword similarity (up to 30), location (up to 25), and event date proximity (up to 15).
- Start with threshold 60/100 and tune with examples.
- Explain that scores are similarity indicators, not probability or confirmation.

**Pass condition:** exact, partial, wrong-category, different-location, distant-date, and no-candidate tests behave as expected.

## M7 — WhatsApp and moderation

- Add reporter contact opt-in in Profile.
- Fetch a contact only through the authenticated permission-checked function; do not query another user's `user_contacts` row directly.
- Open WhatsApp with `url_launcher` and a prefilled message. Handle missing app/failing URL.
- Implement report flags and admin review/hide functions.
- When hiding a report because its image contains sensitive information, remove the image object as part of moderation.
- Assign admin through trusted Supabase Dashboard/SQL only.

**Pass condition:** contact action is unavailable if reporter hasn't opted in; ordinary users cannot assign admin, review flags, or hide other reports.

## M8 — QA and release

Run:

```bash
dart format .
flutter analyze
flutter test
flutter build apk --release
```

Manually test:

- Guest browse, search, filter, and detail.
- Guest taps Lapor, signs in, and continues to the form.
- Sign-up/login/reset-password/logout.
- User creates, edits, resolves, and deletes their report.
- User B cannot modify User A's report.
- Public query cannot read private contact details or hidden/resolved reports.
- Matching cases: exact, partial, wrong category/location/date, no candidates.
- Contact opt-in and failed WhatsApp launch.
- Storage upload/delete policies and failed-upload fallback.
- Flags/admin moderation.
- No internet, empty results, form validation, and retry.

**Pass condition:** tests/analyzer results are reviewed, APK installs and runs on Android, and all core flows can be demonstrated without intentionally paid services.

## Prompt for Antigravity — first implementation task

> Read `AGENTS.md`, `PRD.md`, `DATA_MODEL.md`, `UI_UX_DESIGN.md`, and this roadmap. First inspect the existing Flutter project and report environment issues. Do not edit code yet. After that, work only on M1: implement the FoundIt visual theme and the three-part bottom navigation with mock data. Do not connect Supabase until the mock UI is reviewed. Before editing, list the files you will change and how you will test them. After implementation, run `dart format .`, `flutter analyze`, and relevant tests; report actual results and give me manual test steps. Do not proceed to M2.
