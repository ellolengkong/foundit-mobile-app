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

  static bool _initialized = false;

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
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be provided via '
        '--dart-define-from-file=.env',
      );
    }

    await Supabase.initialize(url: url, publishableKey: anonKey);
    _initialized = true;
  }

  /// The global Supabase client instance.
  ///
  /// Only valid after [initialize] has completed.
  static SupabaseClient get client => Supabase.instance.client;
}
