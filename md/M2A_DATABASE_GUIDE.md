# M2A — Database, RLS & Storage Guide

**Milestone:** M2A — Supabase Schema, RLS Policies, and Storage  
**Status:** Timestamped migration files created; ready for review prior to CLI deployment.

## 1. Migration files

Migrations follow the Supabase CLI timestamp naming convention:

| File | Purpose |
|---|---|
| `supabase/migrations/20261024045913_schema.sql` | Tables, constraints, indexes, triggers, helper functions (`is_admin()`), and `public_reports` view |
| `supabase/migrations/20261024050151_rls_policies.sql` | RLS enable, column-level least-privilege grants, row-level policies, and admin moderation RPCs |
| `supabase/migrations/20261024050328_storage.sql` | `report-photos` bucket creation and folder-scoped Storage RLS policies |

Migrations must be applied **in order** by the Supabase CLI, which executes them chronologically based on timestamps.

## 2. How to apply migrations (CLI workflow only)

Migrations must be applied exclusively through the Supabase CLI to ensure that migration versions are recorded in `supabase_migrations.schema_migrations`.

> [!WARNING]
> **Do NOT copy-paste migration SQL into the Supabase Dashboard SQL Editor.**
> Applying migrations manually in the SQL Editor bypasses the Supabase migration history table (`supabase_migrations.schema_migrations`). This causes migration drift, prevents rollback tracking, and will cause subsequent `supabase db push` commands to fail. The SQL Editor is reserved strictly for read-only inspection or emergency maintenance.

### Standard deployment workflow

```bash
# 1. Ensure project is linked (one-time setup)
supabase link --project-ref YOUR_PROJECT_REF

# 2. Review pending migrations
supabase migration list

# 3. Apply pending migrations to the remote database
supabase db push
```

### Local development workflow (when Docker is available)

```bash
# Start local containers
supabase start

# Apply pending migrations locally
supabase migration up
```

## 3. Database objects created

### Tables

| Table | Primary Key | Description |
|---|---|---|
| `profiles` | `id` (uuid, FK → auth.users) | User profile + role (`user` / `admin`) |
| `user_contacts` | `user_id` (uuid, FK → auth.users) | Private WhatsApp contact preference |
| `reports` | `id` (uuid, auto-generated) | Lost/found reports |
| `report_flags` | `id` (uuid, auto-generated) | Abuse flags on reports |

### View

| View | Description |
|---|---|
| `public_reports` | Read-only, active+visible reports with safe columns only (`security_barrier = true`). Never exposes `owner_id`, `moderation_status`, or contact details. Keeps `security_invoker = false` so base table `reports` can keep `owner_id` fully private from other users. |

### Functions

| Function | Type | Description |
|---|---|---|
| `is_admin()` | Helper | Checks `public.profiles.role` for 'admin' as the single source of truth. `SECURITY DEFINER` with empty `search_path`. Execution revoked from `anon` and granted to `authenticated`. Never trusts client `user_metadata`. |
| `handle_updated_at()` | Trigger fn | Sets `updated_at = now()` on UPDATE. Execution revoked from application roles. |
| `handle_new_user()` | Trigger fn | Creates profile row on Auth signup, always role='user'. Sanitizes empty names with fallback 'Pengguna Baru'. |
| `get_reporter_whatsapp_for_report(uuid)` | RPC | Returns WhatsApp number if caller authenticated, report active+visible, caller not owner, and owner opted in. `SECURITY DEFINER`. |
| `admin_set_report_moderation(uuid, text)` | RPC | Admin-only: set report moderation_status to visible/hidden. |
| `admin_review_flag(uuid, text)` | RPC | Admin-only: update flag review_status to open/reviewed/dismissed. |

### Triggers

| Trigger | Table | Event | Purpose |
|---|---|---|---|
| `on_auth_user_created` | `auth.users` | AFTER INSERT | Auto-create profile row (always role='user') |
| `profiles_updated_at` | `profiles` | BEFORE UPDATE | Set updated_at |
| `user_contacts_updated_at` | `user_contacts` | BEFORE UPDATE | Set updated_at |
| `reports_updated_at` | `reports` | BEFORE UPDATE | Set updated_at |

### Indexes

| Index | Columns | Purpose |
|---|---|---|
| `idx_reports_feed` | `(status, moderation_status, created_at DESC)` | Feed queries |
| `idx_reports_type_category` | `(report_type, category, status)` | Type/category filters |
| `idx_reports_location` | `(campus_area, building_name)` | Location filters |
| `idx_reports_owner` | `(owner_id, created_at DESC)` | My Reports |
| `idx_report_flags_moderation` | `(report_id, review_status)` | Flag moderation |

### Storage

| Bucket | Public | Max Size | MIME Types |
|---|---|---|---|
| `report-photos` | Yes (for direct CDN URL viewing) | 1 MB | image/jpeg, image/png, image/webp |

## 4. Access matrix

| Action | Guest (anon) | Authenticated User | Report Owner | Admin |
|---|---|---|---|---|
| Read public reports | ✅ via `public_reports` view | ✅ via `public_reports` | ✅ | ✅ |
| Read resolved/hidden reports | ❌ | ❌ | ✅ own only | ✅ all |
| Create report | ❌ | ✅ (column grant: content/location only; no `id`, `owner_id`, `status`, `moderation_status`, timestamps) | ✅ | ✅ |
| Edit own report | ❌ | ❌ | ✅ (safe columns only) | ✅ via RPC |
| Delete own report | ❌ | ❌ | ✅ | ✅ |
| Change `owner_id` | ❌ | ❌ | ❌ (excluded from grant) | ❌ |
| Change `moderation_status` | ❌ | ❌ (excluded from grant) | ❌ | ✅ via `admin_set_report_moderation()` |
| Read own profile | ❌ | ✅ own | ✅ own | ✅ all |
| Update own `full_name` | ❌ | ✅ | ✅ | ✅ |
| Change own `role` to admin | ❌ | ❌ | ❌ | ❌ (trusted SQL only) |
| Create/update own contact | ❌ | ✅ (column grant: no `updated_at`) | ✅ own | ❌ others' |
| Read own contacts | ❌ | ✅ own | ✅ own | ❌ others' |
| Read others' contacts | ❌ | ❌ | ❌ | ❌ |
| Request WhatsApp via RPC | ❌ | ✅ (if 4 conditions pass) | ❌ (own report blocked) | ✅ (if conditions pass) |
| Submit flag | ❌ | ✅ (column grant: no `id`, `review_status`, `created_at`; own report blocked via `NOT EXISTS`) | ❌ (own report blocked) | Optional |
| Review flags | ❌ | ❌ (excluded from grant) | ❌ | ✅ via `admin_review_flag()` |
| List/query `storage.objects` | ❌ | ✅ own folder only | ✅ own folder only | ✅ own folder |
| Upload photo | ❌ | ✅ own folder only | ✅ own folder only | ✅ own folder |
| Delete photo | ❌ | ❌ | ✅ own folder only | ✅ any (moderation) |

## 5. Testing the WhatsApp function

The `get_reporter_whatsapp_for_report(report_id)` function returns a phone number **only** when ALL conditions are true:

1. **Caller is authenticated** — anon calls return an error.
2. **Report exists and is `active` + `visible`** — resolved/hidden reports return NULL.
3. **Caller is NOT the report owner** — own reports return NULL.
4. **Owner has a WhatsApp number AND opted in** (`allow_whatsapp_contact = true`) — returns NULL otherwise.

### Test scenarios

```sql
-- As User B, request WhatsApp for User A's active+visible report
-- (User A has whatsapp_number set and allow_whatsapp_contact = true)
SELECT public.get_reporter_whatsapp_for_report('report-uuid-here');
-- Expected: returns the phone number

-- Same but User A has NOT opted in
-- Expected: returns NULL

-- User A trying to get their own report's WhatsApp
-- Expected: returns NULL

-- Anon/guest calling
-- Expected: raises 'Authentication required' error

-- Report is resolved or hidden
-- Expected: returns NULL
```

## 6. Storage configuration & policy notes

### Path convention & storage parameters

- **Bucket name**: `report-photos` (registered as a public bucket for CDN access).
- **Object path format**: `{report_id}/photo` (fixed path without file extension; exactly one photo object per report).
- **Database column**: `reports.photo_path` stores ONLY the bucket-relative object path (e.g. `c0a80123-4567-89ab-cdef-0123456789ab/photo`), **never** prefixed with `report-photos/` or the full URL.
- **Allowed MIME types & size**: `image/jpeg`, `image/png`, `image/webp`, maximum 1 MB (1048576 bytes).
- **Client upload content type**: The application sends the actual file MIME type (e.g. `contentType: 'image/jpeg'`) in `FileOptions` upon upload so Supabase Storage sets the proper HTTP response header.
- **Client URL construction**: Built via the Supabase Storage SDK passing bucket and path as separate parameters:
  ```dart
  final publicUrl = supabase.storage.from('report-photos').getPublicUrl(report.photoPath);
  ```
- **Privacy protection**: The path contains only the `report_id`, ensuring that the reporter's `owner_id` is never leaked in the public feed or `public_reports` view.
- **Upload workflow**:
  1. The client first inserts the report into `public.reports`, obtaining the generated `report_id`.
  2. The client uploads the photo to `report-photos` at `{report_id}/photo`, specifying the appropriate MIME `contentType`.
  3. The client updates `reports.photo_path` with `{report_id}/photo`.

### Storage policies on `storage.objects`

1. `storage_report_photos_select_own`: Authenticated users can only SELECT / list objects for reports they actually own (`EXISTS (SELECT 1 FROM public.reports r WHERE r.id::text = (storage.foldername(name))[1] AND r.owner_id = auth.uid())`), strictly requiring `name = (storage.foldername(name))[1] || '/photo'`.
2. `storage_report_photos_insert`: Authenticated users can only INSERT objects if the folder matches an existing report they own in `public.reports` and the file name is strictly `photo` (no subfolders or alternate names).
3. `storage_report_photos_update`: Authenticated users can only UPDATE / replace files for reports they own in `public.reports`, matching the exact path `{report_id}/photo`.
4. `storage_report_photos_delete_own`: Authenticated users can only DELETE files for reports they own in `public.reports`, matching the exact path `{report_id}/photo`.
5. `storage_report_photos_delete_admin`: Admins (`public.is_admin() = true`) can DELETE any file for moderation.

## 7. How to assign admin role

Admin role is **never** set through user registration or client metadata. To make a user an admin, execute directly on the database via trusted administration:

```sql
UPDATE public.profiles SET role = 'admin' WHERE id = 'USER_UUID_HERE';
```

Because `is_admin()` queries `public.profiles.role` directly as the single source of truth, this change takes effect immediately without requiring JWT manipulation or token refresh.

## 8. Manual actions still required (Post-Approval)

| Action | Status | Notes |
|---|---|---|
| Link Supabase project | ❓ Pending | `supabase link --project-ref <id>` |
| Run `supabase db push` | ❓ Pending | Applies the 3 timestamped migrations via CLI |
| Verify bucket in Dashboard | ❓ Pending | Confirm `report-photos`, public, 1 MB limit, MIME types |
| Test with guest account | ❓ Pending | Verify `public_reports` view returns only safe active/visible data |
| Test with User A / User B | ❓ Pending | Verify cross-user restrictions and column grants |
| Test admin moderation | ❓ Pending | Assign admin role in profiles, test RPCs |
| Test WhatsApp RPC | ❓ Pending | Verify all 4 conditions |
| Test Storage report ownership | ❓ Pending | Verify upload/update/delete requires owning the report in `public.reports` |

## 9. Next steps (M2B+)

After M2A is approved and applied:

1. **M2B**: Supabase Client Connection & Configuration in Flutter.
2. **M2C**: Authentication Flow (Supabase Auth sign-up, login, logout, profile creation trigger).
3. **M2D**: Report CRUD & Photo Upload Integration (creating report first, then uploading to `{report_id}/photo.jpg`).

Do **not** proceed to M2B until all M2A tests pass.
