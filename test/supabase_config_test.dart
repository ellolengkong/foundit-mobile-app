import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/core/services/supabase_service.dart';

void main() {
  group('SupabaseService configuration tests', () {
    test('isConfigured returns false when credentials are not provided via '
        '--dart-define (unit test environment)', () {
      // In the test runner, String.fromEnvironment always returns ''
      // unless explicitly supplied via --dart-define.
      expect(SupabaseService.isConfigured, isFalse);
    });

    test('isInitialized returns false before any initialization attempt', () {
      expect(SupabaseService.isInitialized, isFalse);
    });

    test('initializeIfConfigured returns false in debug mode when no '
        'credentials are supplied (mock fallback allowed)', () async {
      // In the Flutter test runner, kReleaseMode is false (debug mode).
      // Without --dart-define credentials, this should return false
      // rather than throwing, allowing mock services in dev/test.
      final result = await SupabaseService.initializeIfConfigured();
      expect(result, isFalse);
    });

    test('useMockServices is true when Supabase is not initialized', () {
      expect(SupabaseService.useMockServices, isTrue);
    });

    test('initialize throws StateError when credentials are missing', () async {
      // Without --dart-define credentials, initialize() must throw.
      expect(
        () => SupabaseService.initialize(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('SUPABASE_URL'),
          ),
        ),
      );
    });

    test('error messages do not contain actual API key values', () async {
      try {
        await SupabaseService.initialize();
      } on StateError catch (e) {
        // The error message should reference the variable names,
        // but must never contain an actual key value.
        expect(e.message, contains('SUPABASE_URL'));
        expect(e.message, contains('SUPABASE_ANON_KEY'));
        // The placeholder values from .env.example should never appear.
        expect(e.message, isNot(contains('supabase.co')));
        expect(e.message, isNot(contains('eyJ')));
      }
    });
  });
}
