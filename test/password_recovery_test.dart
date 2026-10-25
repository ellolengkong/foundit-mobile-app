import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/app.dart';
import 'package:foundit/data/mock/mock_auth_service.dart';
import 'package:foundit/data/mock/mock_flag_repository.dart';
import 'package:foundit/data/mock/mock_report_repository.dart';
import 'package:foundit/screens/auth/forgot_password_screen.dart';
import 'package:foundit/screens/auth/password_recovery_screen.dart';

void main() {
  testWidgets('Recovery flow validates, completes, and returns to the app', (
    tester,
  ) async {
    final auth = MockAuthService()..beginPasswordRecoveryForTesting();

    await tester.pumpWidget(
      FoundItApp(
        repository: MockReportRepository(),
        authService: auth,
        flagRepository: MockFlagRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PasswordRecoveryScreen), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('recovery-password')),
      'secret1',
    );
    await tester.enterText(
      find.byKey(const Key('recovery-password-confirmation')),
      'different',
    );
    await tester.tap(find.text('Simpan Kata Sandi Baru'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi kata sandi tidak cocok.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('recovery-password-confirmation')),
      'secret1',
    );
    await tester.tap(find.text('Simpan Kata Sandi Baru'));
    await tester.pumpAndSettle();

    expect(find.text('Kata Sandi Berhasil Diperbarui'), findsOneWidget);
    await tester.tap(find.text('Lanjut ke FoundIt'));
    await tester.pumpAndSettle();
    expect(find.text('FoundIt'), findsOneWidget);
  });

  testWidgets('An expired recovery link offers a way to request a new one', (
    tester,
  ) async {
    final auth = MockAuthService()
      ..failPasswordRecoveryForTesting(
        'Tautan reset sudah kedaluwarsa atau pernah digunakan. '
        'Minta tautan baru dan buka tautan terbaru satu kali saja.',
      );

    await tester.pumpWidget(
      FoundItApp(
        repository: MockReportRepository(),
        authService: auth,
        flagRepository: MockFlagRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tautan Reset Tidak Berlaku'), findsOneWidget);
    expect(find.textContaining('sudah kedaluwarsa'), findsOneWidget);

    await tester.tap(find.text('Minta Tautan Reset Baru'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(auth.passwordRecoveryError, isNull);
  });

  testWidgets(
    'Recovery screen replaces an open email-sent route without pressing back',
    (tester) async {
      final auth = MockAuthService();

      await tester.pumpWidget(
        FoundItApp(
          repository: MockReportRepository(),
          authService: auth,
          flagRepository: MockFlagRepository(),
        ),
      );
      await tester.pumpAndSettle();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push<void>(
          MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.tap(find.text('Kirim Tautan Reset'));
      await tester.pumpAndSettle();
      expect(find.text('Kembali ke Halaman Masuk'), findsOneWidget);

      auth.beginPasswordRecoveryForTesting();
      await tester.pumpAndSettle();

      expect(find.byType(PasswordRecoveryScreen), findsOneWidget);
      expect(find.text('Buat Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Kembali ke Halaman Masuk'), findsNothing);
    },
  );
}
