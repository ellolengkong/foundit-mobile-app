# Push notifications setup

## Current platform status

- Firebase project: `foundit-unsrat`
- Android Firebase app: `com.example.foundit`
- Android FlutterFire options: `lib/firebase_options.dart`
- Android Firebase SDK file: `android/app/google-services.json` (ignored by Git)
- iOS is not configured yet. Register `com.example.foundit` as an iOS app and upload an APNs authentication key before enabling iOS messaging.

The Android client requests notification permission after account login, registers its FCM token through authenticated Supabase RPCs, displays messages received in the foreground, and opens the in-app notifications screen when a push is tapped.

## Supabase setup

1. Apply `supabase/migrations/20261106230000_push_notification_tokens.sql`.
2. Deploy the Edge Function:

   ```powershell
   npx --yes supabase@2.122.0 functions deploy send-push-notification --project-ref zjsisdtlfwtveneutyqd --no-verify-jwt
   ```

3. In Firebase Console, create a dedicated service account for Firebase Cloud Messaging with permission to send FCM messages. Download its JSON key and keep it outside the repository. Do not use a client app configuration file (`google-services.json`) as a service account.
4. In Supabase Dashboard → Edge Functions → Secrets, set:
   - `FIREBASE_SERVICE_ACCOUNT`: the complete service-account JSON contents.
   - `PUSH_WEBHOOK_SECRET`: a new, long random secret.

   Generate a random secret locally without sending it in chat:

   ```powershell
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```

5. In Supabase Dashboard → Database → Webhooks, create an `INSERT` webhook for `public.notifications`. Point it to:

   ```text
   https://zjsisdtlfwtveneutyqd.supabase.co/functions/v1/send-push-notification
   ```

   Add this request header, using the same secret configured above:

   ```text
   x-push-webhook-secret: <PUSH_WEBHOOK_SECRET>
   ```

   The endpoint deliberately disables Supabase JWT verification and authenticates the webhook with this separate secret. Keep the secret private and rotate it in both places if it is exposed.

6. Install the updated app on an Android device, sign in, and allow notifications. Trigger a report status change or create a matching report from another account to verify delivery. Background/closed-app display depends on Android notification permission and network availability.

## Local checks

```powershell
flutter analyze
flutter test
flutter run -d <android-device-id>
```

The account token registration RPCs require the migration above. Until it is applied, in-app notifications continue to work, but FCM device registration reports a server error and pushes cannot be delivered.
