import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/services/auth_service.dart';
import 'core/services/flag_repository.dart';
import 'core/services/report_repository.dart';
import 'core/services/supabase_auth_service.dart';
import 'core/services/supabase_flag_repository.dart';
import 'core/services/supabase_report_repository.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'data/mock/foundit_scope.dart';
import 'data/mock/mock_auth_service.dart';
import 'data/mock/mock_flag_repository.dart';
import 'data/mock/mock_report_repository.dart';
import 'screens/auth/password_recovery_screen.dart';
import 'screens/shell/app_shell.dart';

/// Root application widget.
class FoundItApp extends StatefulWidget {
  const FoundItApp({
    super.key,
    this.repository,
    this.authService,
    this.flagRepository,
  });

  final ReportRepository? repository;
  final AuthService? authService;
  final FlagRepository? flagRepository;

  @override
  State<FoundItApp> createState() => _FoundItAppState();
}

class _FoundItAppState extends State<FoundItApp> {
  late final ReportRepository _repository;
  late final AuthService _authService;
  late final FlagRepository _flagRepository;
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _recoveryRouteActive = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? _resolveReportRepository();
    _authService = widget.authService ?? _resolveAuthService();
    _flagRepository = widget.flagRepository ?? _resolveFlagRepository();
    _authService.addListener(_syncRecoveryRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRecoveryRoute());
  }

  @override
  void dispose() {
    _authService.removeListener(_syncRecoveryRoute);
    super.dispose();
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
