import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/app.dart';
import 'package:foundit/data/mock/mock_auth_service.dart';
import 'package:foundit/data/mock/mock_report_repository.dart';

void main() {
  group('Navigation & App Flow Tests', () {
    testWidgets('Guest sees login prompt on FAB tap', (tester) async {
      final auth = MockAuthService();
      final repo = MockReportRepository();

      await tester.pumpWidget(FoundItApp(repository: repo, authService: auth));
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify guest dialog appears with Batal, Daftar, and Masuk
      expect(find.text('Perlu Masuk Akun'), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets(
      'Guest taps FAB -> logs in -> automatically opens CreateReportScreen',
      (tester) async {
        final auth = MockAuthService();
        final repo = MockReportRepository();

        await tester.pumpWidget(
          FoundItApp(repository: repo, authService: auth),
        );
        await tester.pumpAndSettle();

        // 1. Tap FAB
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // 2. Tap 'Masuk' in prompt dialog
        await tester.tap(find.text('Masuk'));
        await tester.pumpAndSettle();

        // Verify LoginScreen is shown
        expect(find.text('Masuk ke FoundIt'), findsOneWidget);
        expect(find.text('Email Kampus / Pribadi *'), findsOneWidget);

        // Fill credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Anda'),
          'test@unsrat.ac.id',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan kata sandi'),
          'password123',
        );

        // Tap Masuk button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        // Should now be on CreateReportScreen directly
        expect(find.text('Buat Laporan'), findsOneWidget);
      },
    );

    testWidgets(
      'Guest taps FAB -> registers -> automatically opens CreateReportScreen',
      (tester) async {
        final auth = MockAuthService();
        final repo = MockReportRepository();

        await tester.pumpWidget(
          FoundItApp(repository: repo, authService: auth),
        );
        await tester.pumpAndSettle();

        // 1. Tap FAB
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // 2. Tap 'Daftar' in prompt dialog
        await tester.tap(find.text('Daftar'));
        await tester.pumpAndSettle();

        // Verify SignupScreen is shown
        expect(find.text('Daftar Akun Baru'), findsOneWidget);

        // Fill registration form
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nama lengkap Anda'),
          'Budi Santoso',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Anda'),
          'budi@unsrat.ac.id',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nomor Whatsapp Anda'),
          '081234567890',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Minimal 6 karakter'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Ulangi kata sandi'),
          'password123',
        );

        final submitBtn = find.widgetWithText(ElevatedButton, 'Daftar Akun');
        await tester.ensureVisible(submitBtn);
        await tester.pumpAndSettle();

        // Submit registration
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Should now be on CreateReportScreen directly
        expect(find.text('Buat Laporan'), findsOneWidget);
      },
    );

    testWidgets('Switching between Beranda and Profil tabs', (tester) async {
      final auth = MockAuthService();
      final repo = MockReportRepository();

      await tester.pumpWidget(FoundItApp(repository: repo, authService: auth));
      await tester.pumpAndSettle();

      // Tap Profil tab
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      // In guest state, user sees guest notice
      expect(find.text('Anda Masuk sebagai Tamu'), findsOneWidget);
      expect(find.text('Bergabung dan lakukan lebih banyak'), findsOneWidget);

      // Tap Beranda tab
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();

      expect(find.text('FoundIt'), findsOneWidget);
    });

    testWidgets('Tapping report card opens detail screen', (tester) async {
      final auth = MockAuthService();
      final repo = MockReportRepository();

      await tester.pumpWidget(FoundItApp(repository: repo, authService: auth));
      await tester.pumpAndSettle();

      final firstReport = repo.getPublicReports().first;

      // Find and tap the first report card item
      final firstReportFinder = find.text(firstReport.itemName).first;
      await tester.ensureVisible(firstReportFinder);
      await tester.tap(firstReportFinder);
      await tester.pumpAndSettle();

      // Detail screen has title 'Detail Laporan' and description section
      expect(find.text('Detail Laporan'), findsOneWidget);
      expect(find.text('Deskripsi Publik'), findsOneWidget);
    });
  });
}
