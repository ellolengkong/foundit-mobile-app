# Product Requirements Document (PRD) — FoundIt

**Product:** FoundIt — Lost & Found UNSRAT  
**Tagline:** *Lost Today, Found Tomorrow.*  
**Version:** 1.1 — MVP baseline  
**Platform:** Android  
**Frontend:** Flutter + Dart  
**Backend:** Supabase Auth + PostgreSQL + Supabase Storage  
**Development workflow:** Antigravity in VS Code with Git

## 1. Product overview

FoundIt is a mobile application for the UNSRAT campus community to report and search for lost or found items. It centralizes reports, lets guests browse without an account, recommends potentially matching reports, and helps users contact a consenting reporter through WhatsApp.

## 2. Goals

- Make campus lost/found reports available in one place.
- Let users browse and search public reports without being forced to sign in.
- Let registered users create and manage their own reports.
- Recommend potentially matching lost/found reports using a simple, explainable score.
- Keep contact details and account permissions protected.
- Build and demonstrate the MVP without intentionally upgrading to a paid service tier.

## 3. Roles

- **Guest:** browse, search, filter, and view public active reports.
- **Registered user:** all guest actions plus create/edit/delete own reports, mark own reports resolved, flag problematic reports, and request WhatsApp contact when the reporter opted in.
- **Admin:** review abuse flags and hide inappropriate or misleading reports. Admin role is assigned only through a trusted Supabase Dashboard/SQL process; registration never lets a user choose the role.

## 4. MVP features

### 4.1 Public home and detail

Show active, visible reports. The public feed and detail include item name, category, report type, public description, location, event date, and optional photo. Do not expose phone numbers, account IDs, or other private contact data in public report views.

### 4.2 Authentication

Use Supabase Auth email/password sign-up, login, password reset, and logout. Browsing does not require login. Creating or managing reports and opening the WhatsApp contact action require login. If a guest taps the central `+` action, route them to login/sign-up and continue to the report form after successful authentication.

### 4.3 Report creation and management

A signed-in user can create, edit, and delete their own reports. Required fields:

- Report type: `lost` or `found`.
- Item name.
- Category.
- Campus area/faculty.
- Event date.

Optional fields: public description, one photo, building/facility, and specific-location text. Validate inputs and provide loading, success, empty, and error states. The UI must remind users not to publish ID numbers, bank-card data, or unique ownership clues in the public description or image.

### 4.4 Search and filters

Support a simple keyword search against item name and public description. Filters: report type, category, campus area/faculty, building/facility, and event date. By default, show only active and visible reports. Full-text search infrastructure is out of MVP scope.

### 4.5 Campus location

Use a manual location hierarchy: campus area/faculty → building/facility → specific-location text. Include `Area Umum Kampus`, `Lainnya`, and `Tidak tahu lokasi persis`. Verify area/building names with the team; do not invent official building names. No GPS or interactive map in the MVP.

### 4.6 Rule-based matching

Compare only opposite report types (`lost` versus `found`) that are active and visible. Initial score:

- Same category: 30 points.
- Item-name/public-description keyword similarity: up to 30 points.
- Same/nearby campus location: up to 25 points.
- Nearby event date: up to 15 points.

Initially show scores of 60/100 or above as **Kemungkinan cocok**. This is a heuristic score, not a probability or confirmation. Test the threshold using sample reports and adjust if needed. Calculate results when opening the matching screen or after a report is submitted; do not add a matches table or push notifications in the MVP.

### 4.7 WhatsApp contact

Use `url_launcher` to open WhatsApp with a prefilled message. The reporter must explicitly opt in to WhatsApp contact. Only signed-in users may request contact details, and only for an active, visible report. Do not expose `user_contacts` directly to guests or other users; use a permission-checked Postgres RPC/function. The app must handle WhatsApp not being installed or the link failing.

### 4.8 Report status and moderation

Use two report statuses: `active` and `resolved`.

- `active`: the item is still being searched for or has not yet been returned.
- `resolved`: the owner considers the report resolved.

Moderation is separate: `visible` or `hidden`. Only admin may change moderation status. Public screens default to active + visible reports. Users can flag a report as spam, false information, inappropriate, or exposing personal data. Admin can review flags and hide problematic reports.

## 5. Item categories

Use these stable keys in the database and Indonesian labels in the UI:

1. `electronics_gadgets` — Elektronik & Gadget
2. `wallet_money` — Dompet & Uang
3. `cards_documents` — Kartu & Dokumen
4. `keys_access` — Kunci & Akses
5. `bags_pouches` — Tas & Pouch
6. `books_stationery` — Buku & Alat Tulis
7. `clothing_equipment` — Pakaian & Perlengkapan
8. `personal_accessories` — Aksesori Pribadi
9. `bottles_food_containers` — Botol & Wadah Makanan
10. `other` — Lainnya

## 6. Navigation and UI

The main navigation has three actions:

- **Beranda:** search, quick filters, active reports, and an entry point to possible matches.
- **Central `+` Lapor:** opens the report form if authenticated; otherwise routes through login/sign-up and then back to the requested form.
- **Profil:** profile, My Reports, Possible Matches, contact preference, and logout; guests see Login/Sign Up.

Follow `UI_UX_DESIGN.md`: friendly modern visual style, Soft Indigo palette, Plus Jakarta Sans, uncluttered forms, and consistent loading/empty/error/success states.

## 7. Backend and data security

Use `DATA_MODEL.md` as the authoritative source for names and behavior. Supabase tables: `profiles`, `user_contacts`, `reports`, and `report_flags`, plus the `public_reports` view. Supabase Auth owns passwords and authentication IDs. Supabase Storage holds optional public report photos in a bucket named `report-photos`.

- Enable and test Row Level Security (RLS) on every exposed table.
- Public screens read through `public_reports`, which contains only safe public fields and filters to active/visible reports.
- Do not expose `user_contacts` directly. Contact lookup must use a permission-checked function and require opt-in.
- Restrict admin role changes and moderation operations to trusted/admin-only database operations.
- Never put a Supabase `service_role`/secret key in Flutter, source control, prompts, logs, or screenshots. The client uses only the project URL and publishable/anon key with RLS.
- Keep database changes in versioned SQL migration files under `supabase/migrations/`.

## 8. Photo storage and free-tier constraint

Photo is optional and limited to one image per report for the MVP. Use Supabase Storage bucket `report-photos`, with an initial maximum file size of about 1 MB and allowed MIME types JPEG, PNG, and WebP. Compress images before upload and show a placeholder if the report has no image or upload fails.

The bucket is intended for public report images: anyone with the image URL may view the image. Therefore, prohibit photos containing readable student/identity numbers, bank-card data, private documents, or other sensitive material. Upload/update/delete permissions must be restricted by Storage policies so users only manage objects in their own user-ID folder. Admin moderation of an image should remove the image object as well as hide the report when appropriate.

Use Supabase Free only; do not intentionally upgrade or add paid services. Free-tier quota limits and inactivity pauses may apply, so check the current Supabase dashboard before demonstrations and monitor storage/egress. Do not promise unlimited or permanently uninterrupted free use.

## 9. Out of scope

- Internal chat/calls.
- Push notifications.
- GPS, geofencing, and interactive maps.
- AI image recognition or image similarity.
- External full-text search service.
- User reputation, complex analytics, and multi-campus administration.

## 10. Acceptance criteria

1. Guests can browse, search, filter, and view active public reports without login.
2. Guests tapping Lapor are routed through authentication and continue to the report form after login.
3. Users can create/edit/delete only their own reports and mark them resolved.
4. RLS prevents unauthorized reads/writes; a regular user cannot assign themselves the admin role or change moderation status.
5. Search and filters return reports consistent with selected values.
6. Matching compares opposite report types and presents heuristic recommendations, not certainty.
7. Contact details are not public; WhatsApp contact works only for signed-in users when the reporter opted in.
8. Resolved/hidden reports do not appear in the default public feed.
9. Storage policies restrict upload/update/delete to the file owner; sensitive images are prohibited.
10. Admin can review abuse flags and hide problematic reports.
11. `dart format`, `flutter analyze`, automated tests, manual core-flow tests, and release APK build pass.
12. The application runs under the selected free-tier configuration without intentionally enabling paid services.
