import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'supabase_service.dart';

const _notificationChannelId = 'foundit_notifications';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

class PushNotificationService {
  PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Completer<String> _registrationCompleter = Completer<String>();
  String? _userId;
  String? _deviceRegistrationId;
  bool _isRegistered = false;
  bool _permissionRequested = false;
  Map<String, dynamic>? _pendingTapData;
  ValueChanged<Map<String, dynamic>>? onNotificationTap;

  static Future<PushNotificationService?> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final service = PushNotificationService._();
    await service._initializeLocalNotifications();
    service._listenForMessages();
    await service._messaging.register();
    service._isRegistered = true;

    final initialMessage = await service._messaging.getInitialMessage();
    if (initialMessage != null) {
      service._handleNotificationTap(initialMessage.data);
    }

    return service;
  }

  void setNotificationTapHandler(ValueChanged<Map<String, dynamic>>? handler) {
    onNotificationTap = handler;
    final pendingData = _pendingTapData;
    if (handler != null && pendingData != null) {
      _pendingTapData = null;
      scheduleMicrotask(() => handler(pendingData));
    }
  }

  Future<void> bindUser(String? userId) async {
    _userId = userId;
    if (userId == null) return;

    if (!_permissionRequested) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      _permissionRequested = true;
    }
    if (!_isRegistered) {
      _registrationCompleter = Completer<String>();
      await _messaging.register();
      _isRegistered = true;
    }
    final token =
        _deviceRegistrationId ??
        await _registrationCompleter.future.timeout(
          const Duration(seconds: 20),
        );
    if (_userId != userId) return;
    await _registerToken(token);
  }

  Future<void> unregisterCurrentUser() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final token = _deviceRegistrationId;
      if (token != null && SupabaseService.isInitialized) {
        await SupabaseService.client.rpc(
          'unregister_push_device_token',
          params: {'p_token': token},
        );
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'FoundIt push notifications',
          context: ErrorDescription('while unregistering a device token'),
        ),
      );
      try {
        await _messaging.unregister();
        _isRegistered = false;
        _deviceRegistrationId = null;
      } catch (deleteError, deleteStackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: deleteError,
            stack: deleteStackTrace,
            library: 'FoundIt push notifications',
            context: ErrorDescription(
              'while invalidating an unregistered device token',
            ),
          ),
        );
      }
    } finally {
      _userId = null;
    }
  }

  Future<void> _registerToken(String token) async {
    if (!SupabaseService.isInitialized) return;
    await SupabaseService.client.rpc(
      'register_push_device_token',
      params: {'p_token': token, 'p_platform': 'android'},
    );
  }

  Future<void> _initializeLocalNotifications() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_foundit'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          _handleNotificationTap(const {});
          return;
        }
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            _handleNotificationTap(decoded);
          } else {
            _handleNotificationTap(const {});
          }
        } on FormatException catch (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'FoundIt push notifications',
              context: ErrorDescription('while reading notification data'),
            ),
          );
        }
      },
    );

    const channel = AndroidNotificationChannel(
      _notificationChannelId,
      'Notifikasi FoundIt',
      description: 'Pembaruan laporan dan laporan yang mungkin cocok.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _listenForMessages() {
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((message) {
        unawaited(_showForegroundNotification(message));
      }),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _handleNotificationTap(message.data),
      ),
    );
    _subscriptions.add(
      _messaging.onRegistered.listen((token) {
        _deviceRegistrationId = token;
        if (!_registrationCompleter.isCompleted) {
          _registrationCompleter.complete(token);
        }
        if (_userId != null) unawaited(_registerTokenAndReportErrors(token));
      }),
    );
  }

  Future<void> _registerTokenAndReportErrors(String token) async {
    try {
      await _registerToken(token);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'FoundIt push notifications',
          context: ErrorDescription('while refreshing a device token'),
        ),
      );
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    if (title == null || body == null) return;

    try {
      await _localNotifications.show(
        id:
            message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            'Notifikasi FoundIt',
            channelDescription:
                'Pembaruan laporan dan laporan yang mungkin cocok.',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_stat_foundit',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'FoundIt push notifications',
          context: ErrorDescription(
            'while displaying a foreground notification',
          ),
        ),
      );
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final handler = onNotificationTap;
    if (handler == null) {
      _pendingTapData = data;
    } else {
      handler(data);
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }
}
