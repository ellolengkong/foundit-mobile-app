import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/services/auth_service.dart';
import 'core/services/flag_repository.dart';
import 'core/services/notification_repository.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/report_repository.dart';
import 'core/services/supabase_auth_service.dart';
import 'core/services/supabase_flag_repository.dart';
import 'core/services/supabase_notification_repository.dart';
import 'core/services/supabase_report_repository.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'data/mock/foundit_scope.dart';
import 'data/mock/mock_auth_service.dart';
import 'data/mock/mock_flag_repository.dart';
import 'data/mock/mock_notification_repository.dart';
import 'data/mock/mock_report_repository.dart';
import 'screens/auth/password_recovery_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/shell/app_shell.dart';

/// Root application widget.
class FoundItApp extends StatefulWidget {
  const FoundItApp({
    super.key,
    this.repository,
    this.authService,
    this.flagRepository,
    this.notificationRepository,
    this.pushNotificationService,
  });

  final ReportRepository? repository;
  final AuthService? authService;
  final FlagRepository? flagRepository;
  final NotificationRepository? notificationRepository;
  final PushNotificationService? pushNotificationService;

  @override
  State<FoundItApp> createState() => _FoundItAppState();
}

class _FoundItAppState extends State<FoundItApp> {
  late final ReportRepository _repository;
  late final AuthService _authService;
  late final FlagRepository _flagRepository;
  late final NotificationRepository _notificationRepository;
  late final bool _ownsNotificationRepository;
  late final bool _ownsPushNotificationService;
  PushNotificationService? _pushNotificationService;
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _recoveryRouteActive = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? _resolveReportRepository();
    _authService = widget.authService ?? _resolveAuthService();
    _flagRepository = widget.flagRepository ?? _resolveFlagRepository();
    _ownsNotificationRepository = widget.notificationRepository == null;
    _notificationRepository =
        widget.notificationRepository ?? _resolveNotificationRepository();
    _ownsPushNotificationService = widget.pushNotificationService == null;
    _pushNotificationService = widget.pushNotificationService;
    _configurePushNotifications();
    _authService.addListener(_syncRecoveryRoute);
    _authService.addListener(_syncNotificationUser);
    _authService.addListener(_syncPushNotificationUser);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRecoveryRoute());
    _syncNotificationUser();
  }

  @override
  void dispose() {
    _authService.removeListener(_syncRecoveryRoute);
    _authService.removeListener(_syncNotificationUser);
    _authService.removeListener(_syncPushNotificationUser);
    _pushNotificationService?.setNotificationTapHandler(null);
    if (_ownsPushNotificationService) {
      unawaited(_pushNotificationService?.dispose());
    }
    if (_ownsNotificationRepository) _notificationRepository.dispose();
    super.dispose();
  }

  void _configurePushNotifications() {
    final service = _pushNotificationService;
    if (service == null) return;

    service.setNotificationTapHandler(_openNotificationsFromPush);

    final authService = _authService;
    if (authService is SupabaseAuthService) {
      authService.beforeSignOut = service.unregisterCurrentUser;
    }
    _syncPushNotificationUser();
  }

  void _openNotificationsFromPush(Map<String, dynamic> _) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: StateError('Notification navigator is unavailable.'),
            library: 'FoundIt push notifications',
            context: ErrorDescription('while opening a tapped notification'),
          ),
        );
        return;
      }
      navigator.push<void>(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      );
    });
  }

  void _syncPushNotificationUser() {
    final service = _pushNotificationService;
    if (service == null) return;
    unawaited(
      service.bindUser(_authService.currentUser?.id).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'FoundIt push notifications',
            context: ErrorDescription('while binding a device to an account'),
          ),
        );
      }),
    );
  }

  void _syncNotificationUser() {
    unawaited(
      _notificationRepository.bindUser(_authService.currentUser?.id).catchError(
        (Object error, StackTrace stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'FoundIt notifications',
              context: ErrorDescription(
                'while binding notifications to a user',
              ),
            ),
          );
        },
      ),
    );
  }

  void _syncRecoveryRoute() {
    if (!mounted) return;

    final recoveryError = _authService.passwordRecoveryError;
    final shouldShowRecovery =
        recoveryError != null || _authService.isPasswordRecovery;
    final navigator = _navigatorKey.currentState;

    if (!shouldShowRecovery) {
      _recoveryRouteActive = false;
      return;
    }
    if (navigator == null || _recoveryRouteActive) return;

    _recoveryRouteActive = true;
    navigator.pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => recoveryError != null
            ? PasswordRecoveryScreen(errorMessage: recoveryError)
            : const PasswordRecoveryScreen(),
      ),
      (route) => route.isFirst,
    );
  }

  static ReportRepository _resolveReportRepository() {
    if (SupabaseService.isInitialized) {
      return SupabaseReportRepository();
    }
    _assertMockAllowed();
    return MockReportRepository();
  }

  static AuthService _resolveAuthService() {
    if (SupabaseService.isInitialized) {
      return SupabaseAuthService();
    }
    _assertMockAllowed();
    return MockAuthService();
  }

  static FlagRepository _resolveFlagRepository() {
    if (SupabaseService.isInitialized) {
      return SupabaseFlagRepository();
    }
    _assertMockAllowed();
    return MockFlagRepository();
  }

  NotificationRepository _resolveNotificationRepository() {
    if (widget.authService != null || !SupabaseService.isInitialized) {
      _assertMockAllowed();
      return MockNotificationRepository();
    }
    return SupabaseNotificationRepository();
  }

  /// Throws in release mode to prevent silent mock fallback.
  static void _assertMockAllowed() {
    if (kReleaseMode) {
      throw StateError(
        'Supabase belum diinisialisasi. Build release tidak boleh '
        'menggunakan mock services. Pastikan SUPABASE_URL dan '
        'SUPABASE_ANON_KEY dikonfigurasi melalui --dart-define-from-file=.env',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FoundItScope(
      repository: _repository,
      authService: _authService,
      flagRepository: _flagRepository,
      notificationRepository: _notificationRepository,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'FoundIt UNSRAT',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const AppShell(),
      ),
    );
  }
}
