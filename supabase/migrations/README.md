# Supabase migrations

This directory contains versioned SQL migrations for the FoundIt database following Supabase CLI timestamp conventions.

## Migration files

| File | Purpose |
|---|---|
| `20261024045913_schema.sql` | Tables, constraints, indexes, triggers, `is_admin()`, and `public_reports` view |
| `20261024050151_rls_policies.sql` | RLS enable, column-level grants, row-level policies, and admin moderation RPCs |
| `20261024050328_storage.sql` | `report-photos` bucket registration, fixed `{report_id}/photo` Storage policies |

## Storage Convention: `report-photos`

- **Bucket name**: `report-photos` (public bucket for CDN asset access).
- **Object path**: `{report_id}/photo` (fixed path without file extension; exactly one photo object per report).
- **Database field**: `reports.photo_path` stores only the relative object path within the bucket, **without** the bucket name prefix `report-photos/` or full URL (e.g. `c0a80123-4567-89ab-cdef-0123456789ab/photo`).
- **Allowed MIME types & size**: `image/jpeg`, `image/png`, `image/webp`, maximum 1 MB (1048576 bytes).
- **Client upload content type**: The application sends the actual file MIME type (e.g. `contentType: 'image/jpeg'`) in `FileOptions` upon upload so Supabase Storage sets the proper HTTP response header.
- **Client URL construction**: Built via the Supabase Storage SDK with separate bucket and path parameters:
  ```dart
  final publicUrl = supabase.storage.from('report-photos').getPublicUrl(report.photoPath);
  ```
- **Ownership verification**: Storage RLS policies enforce that the folder segment `{report_id}` matches an existing report in `public.reports` where `owner_id = auth.uid()`, and the file name is strictly `photo` (no subfolders or alternate names).

## How to apply

Apply migrations using the Supabase CLI to ensure migrations are tracked in `supabase_migrations.schema_migrations`:

```bash
# Push pending migrations to linked remote project (after review and approval)
supabase db push
```

Do not execute migrations manually by pasting raw SQL into the Supabase Dashboard SQL Editor, as this bypasses migration history tracking.

See [M2A_DATABASE_GUIDE.md](../../md/M2A_DATABASE_GUIDE.md) for detailed specifications, testing procedures, and the access matrix.

## Next Development Milestones

- **M2B**: Supabase Client Connection & Configuration in Flutter.
- **M2C**: Authentication Flow (Supabase Auth sign-up, login, logout, profile creation trigger).
- **M2D**: Report CRUD & Photo Upload Integration.

## Security reminders

- Do not put a Supabase `service_role`/secret key in SQL files, Flutter code, or version control.
- Do not disable RLS or create overly permissive policies.
- Verify policies with guest, User A, User B, and admin accounts before connecting Flutter app.
