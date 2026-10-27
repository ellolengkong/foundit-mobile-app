import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized access to the Supabase client instance.
///
/// [SupabaseService.initialize] must be called once before `runApp()`.
/// After initialization, use [SupabaseService.client] to access the
/// authenticated Supabase client throughout the app.
///
/// Credentials are injected at build time via `--dart-define-from-file`
/// and must never be hard-coded or committed to version control.
class SupabaseService {
  SupabaseService._();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool _initialized = false;

  /// Whether build-time credentials were provided.
  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  /// Whether Supabase has been successfully initialized.
  static bool get isInitialized {
    if (_initialized) return true;
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  /// Whether the app should use mock/in-memory services.
  ///
  /// Returns `true` only in debug/profile mode when Supabase is not
  /// initialized. In release mode, mock fallback is never allowed —
  /// Supabase must be properly configured.
  static bool get useMockServices => !isInitialized;

  /// Initializes the Supabase client with build-time configuration.
  ///
  /// Call this once in `main()` before `runApp()`:
  /// ```dart
  /// await SupabaseService.initialize();
  /// ```
  ///
  /// Requires `SUPABASE_URL` and `SUPABASE_ANON_KEY` to be provided
  /// via `--dart-define-from-file=.env` at build/run time.
  static Future<void> initialize() async {
    if (_url.isEmpty || _anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be provided via '
        '--dart-define-from-file=.env',
      );
    }

    await Supabase.initialize(url: _url, publishableKey: _anonKey);
    _initialized = true;
  }

  /// Initializes Supabase when credentials are supplied; throws in release
  /// mode if credentials are missing or incomplete.
  ///
  /// In debug/profile mode, returns `false` when no credentials are
  /// configured, allowing the app to continue with mock services for
  /// development and testing.
  static Future<bool> initializeIfConfigured() async {
    if (isConfigured) {
      await initialize();
      return true;
    }

    // Detect partial configuration (one value provided but not the other).
    final hasUrl = _url.isNotEmpty;
    final hasKey = _anonKey.isNotEmpty;
    if (hasUrl != hasKey) {
      // One is provided, the other is not — always an error regardless of mode.
      final missing = hasUrl ? 'SUPABASE_ANON_KEY' : 'SUPABASE_URL';
      throw StateError(
        'Konfigurasi Supabase tidak lengkap: $missing tidak tersedia. '
        'Pastikan kedua variabel disediakan melalui --dart-define-from-file=.env',
      );
    }

    // Neither credential provided.
    if (kReleaseMode) {
      throw StateError(
        'Build release memerlukan konfigurasi Supabase. '
        'Sediakan SUPABASE_URL dan SUPABASE_ANON_KEY melalui '
        '--dart-define-from-file=.env',
      );
    }

    // Debug/profile: allow mock fallback for development.
    assert(() {
      debugPrint(
        'SupabaseService: Kredensial tidak dikonfigurasi — '
        'menggunakan mock services (hanya mode pengembangan).',
      );
      return true;
    }());
    return false;
  }

  /// The global Supabase client instance.
  ///
  /// Only valid after [initialize] has completed.
  static SupabaseClient get client => Supabase.instance.client;
}
