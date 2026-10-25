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

  /// Initializes Supabase when credentials are supplied; otherwise the app
  /// can continue with its in-memory mock services.
  static Future<bool> initializeIfConfigured() async {
    if (_url.isEmpty && _anonKey.isEmpty) return false;
    await initialize();
    return true;
  }

  /// The global Supabase client instance.
  ///
  /// Only valid after [initialize] has completed.
  static SupabaseClient get client => Supabase.instance.client;
}
