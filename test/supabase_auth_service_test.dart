import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/core/services/auth_service.dart';
import 'package:foundit/core/services/supabase_auth_service.dart';
import 'package:foundit/data/mock/mock_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthResult & AuthFailure Tests', () {
    test('AuthFailure formats message correctly', () {
      const failure = AuthFailure('Email atau kata sandi salah.');
      expect(failure.message, 'Email atau kata sandi salah.');
      expect(failure.toString(), 'Email atau kata sandi salah.');
    });

    test('AuthResult holds confirmation flag and user', () {
      const result = AuthResult(
        requiresEmailConfirmation: true,
        message: 'Periksa email Anda.',
      );
      expect(result.requiresEmailConfirmation, isTrue);
      expect(result.message, 'Periksa email Anda.');
      expect(result.user, isNull);
    });
  });

  group('SupabaseAuthService Exception Mapping & Normalization', () {
    test('maps invalid login credentials message', () {
      final msg = SupabaseAuthService.mapAuthException(
        const AuthException('Invalid login credentials'),
      );
      expect(msg, 'Email atau kata sandi yang Anda masukkan salah.');
    });

    test('maps email not confirmed message', () {
      final msg = SupabaseAuthService.mapAuthException(
        const AuthException('Email not confirmed'),
      );
      expect(
        msg,
        'Email Anda belum dikonfirmasi. Silakan periksa kotak masuk email Anda.',
      );
    });

    test('maps already registered message', () {
      final msg = SupabaseAuthService.mapAuthException(
        const AuthException('User already registered'),
      );
      expect(
        msg,
        'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk ke akun Anda.',
      );
    });

    test('maps weak password message', () {
      final msg = SupabaseAuthService.mapAuthException(
        const AuthException('Password should be at least 6 characters'),
      );
      expect(msg, 'Kata sandi minimal 6 karakter.');
    });

    test('maps rate limit message', () {
      final msg = SupabaseAuthService.mapAuthException(
        const AuthException('over_email_send_rate_limit'),
      );
      expect(
        msg,
        'Terlalu banyak permintaan. Silakan coba lagi beberapa saat lagi.',
      );
    });

    test('normalizes Indonesian WhatsApp phone numbers', () {
      expect(
        SupabaseAuthService.normalizeWhatsapp('081234567890'),
        '6281234567890',
      );
      expect(
        SupabaseAuthService.normalizeWhatsapp('+62 812-3456-7890'),
        '6281234567890',
      );
      expect(
        SupabaseAuthService.normalizeWhatsapp('6281234567890'),
        '6281234567890',
      );
      expect(SupabaseAuthService.normalizeWhatsapp(''), isNull);
      expect(SupabaseAuthService.normalizeWhatsapp(null), isNull);
    });
  });

  group('AuthService Polymorphism & Mock Compatibility', () {
    test('MockAuthService conforms to AuthService contract', () async {
      final AuthService auth = MockAuthService();

      expect(auth.isLoggedIn, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.isAdminMode, isFalse);
      expect(auth.canAccessAdmin, isFalse);

      await auth.login(
        email: 'test@unsrat.ac.id',
        password: 'password123',
      );
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser?.email, 'test@unsrat.ac.id');

      auth.toggleAdminMode();
      expect(auth.isAdminMode, isTrue);
      expect(auth.canAccessAdmin, isTrue);

      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.isAdminMode, isFalse);
    });

    test('MockAuthService signUp returns AuthResult with active session', () async {
      final AuthService auth = MockAuthService();

      final result = await auth.signUp(
        fullName: 'Budi Santoso',
        email: 'budi@unsrat.ac.id',
        password: 'password123',
        whatsapp: '08123456789',
        allowWhatsappContact: true,
      );

      expect(result.requiresEmailConfirmation, isFalse);
      expect(result.user, isNotNull);
      expect(result.user?.fullName, 'Budi Santoso');
      expect(result.user?.contact?.whatsappNumber, '08123456789');
      expect(result.user?.contact?.allowWhatsappContact, isTrue);
    });

    test('MockAuthService sendPasswordResetEmail completes without error', () async {
      final AuthService auth = MockAuthService();
      await expectLater(
        auth.sendPasswordResetEmail('budi@unsrat.ac.id'),
        completes,
      );
    });
  });
}
