import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initializeIfConfigured();

  PushNotificationService? pushNotificationService;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      pushNotificationService = await PushNotificationService.initialize();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'FoundIt push notifications',
          context: ErrorDescription('while initializing Firebase Messaging'),
        ),
      );
    }
  }

  runApp(FoundItApp(pushNotificationService: pushNotificationService));
}
