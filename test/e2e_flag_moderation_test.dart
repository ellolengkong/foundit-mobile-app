import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/app.dart';
import 'package:foundit/core/constants/report_enums.dart';
import 'package:foundit/data/mock/mock_auth_service.dart';
import 'package:foundit/data/mock/mock_flag_repository.dart';
import 'package:foundit/data/mock/mock_report_repository.dart';
import 'package:foundit/screens/admin/admin_dashboard_screen.dart';

void main() {
  group('E2E Report Flag & Admin Moderation Tests', () {
    testWidgets(
      'Guest is required to login before flagging, then proceeds to flag form',
      (tester) async {
        final auth = MockAuthService();
        final repo = MockReportRepository();
        final flagRepo = MockFlagRepository();

        await tester.pumpWidget(
          FoundItApp(
            repository: repo,
            authService: auth,
            flagRepository: flagRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Open first report detail (mock-001 "Dompet hitam", owned by user-001)
        await tester.tap(find.text('Dompet hitam').first);
        await tester.pumpAndSettle();

        // Guest taps flag icon
        await tester.tap(find.byIcon(Icons.flag_outlined));
        await tester.pumpAndSettle();

        // Verify login prompt appears
        expect(find.text('Perlu Masuk Akun'), findsOneWidget);
        expect(find.text('Masuk'), findsOneWidget);
        expect(find.text('Daftar'), findsOneWidget);

        // Tap 'Masuk'
        await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
        await tester.pumpAndSettle();

        // Fill login form as user-002 (not the owner of mock-001)
        await tester.enterText(
          find.widgetWithText(TextFormField, 'nama@unsrat.ac.id'),
          'user-002@unsrat.ac.id',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan kata sandi'),
          'password123',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        // Verify flag form dialog opens automatically after login
        expect(find.text('Laporkan Laporan Ini'), findsOneWidget);
        expect(find.text('Spam'), findsOneWidget);
        expect(find.text('Informasi Palsu'), findsOneWidget);
      },
    );

    testWidgets(
      'E2E flag submission, admin moderation, visibility toggle, and resolution',
      (tester) async {
        final auth = MockAuthService();
        final repo = MockReportRepository();
        final flagRepo = MockFlagRepository();

        // Log in as user-003 so user can report mock-001 (owned by user-001)
        auth.login(email: 'user-003@unsrat.ac.id', password: 'password123');

        await tester.pumpWidget(
          FoundItApp(
            repository: repo,
            authService: auth,
            flagRepository: flagRepo,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Pengguna mengirim flag dari halaman Detail Barang
        // Tap first report 'Dompet hitam' (mock-001, owned by user-001)
        await tester.tap(find.text('Dompet hitam').first);
        await tester.pumpAndSettle();

        // Tap flag button
        await tester.tap(find.byIcon(Icons.flag_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Laporkan Laporan Ini'), findsOneWidget);

        // Select 'Informasi Palsu' reason
        await tester.tap(find.text('Informasi Palsu'));
        await tester.pumpAndSettle();

        // Tap 'Kirim Laporan'
        await tester.tap(find.text('Kirim Laporan'));
        await tester.pumpAndSettle();

        // Verify snackbar
        expect(
          find.text('Laporan telah dikirim ke tim moderator untuk ditinjau.'),
          findsOneWidget,
        );

        // Pop back to home using BackButton
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // 2. Flag baru muncul pada tab Dilaporkan di Dashboard Admin
        auth.toggleAdminMode();
        final navState = tester.state<NavigatorState>(find.byType(Navigator));
        navState.push(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dashboard Admin (Mock)'), findsOneWidget);

        // Switch to tab 'Dilaporkan'
        await tester.tap(find.text('Dilaporkan'));
        await tester.pumpAndSettle();

        // Verify newly flagged report 'Dompet hitam' is displayed
        expect(find.text('Dompet hitam'), findsWidgets);
        expect(find.text('Alasan: Informasi Palsu'), findsOneWidget);

        // 3. Aksi Abaikan mengubah status flag menjadi dismissed
        // Tap 'Abaikan' on the first visible open flag that has an 'Abaikan' button
        final abaikanButtonFinder = find.widgetWithText(
          OutlinedButton,
          'Abaikan',
        );
        expect(abaikanButtonFinder, findsWidgets);
        await tester.tap(abaikanButtonFinder.first);
        await tester.pump();

        expect(find.text('Laporan penyalahgunaan diabaikan.'), findsOneWidget);
        await tester.pumpAndSettle();

        expect(
          flagRepo.allFlags.any(
            (f) => f.reviewStatus == FlagReviewStatus.dismissed,
          ),
          isTrue,
        );

        // 4. Aksi Sembunyikan & Selesai mengubah visibilitas laporan dan status flag
        final sembunyikanSelesaiFinder = find.widgetWithText(
          FilledButton,
          'Sembunyikan & Selesai',
        );
        expect(sembunyikanSelesaiFinder, findsWidgets);
        await tester.tap(sembunyikanSelesaiFinder.first);
        await tester.pump();

        expect(
          find.text('Laporan disembunyikan dan flag ditandai selesai.'),
          findsOneWidget,
        );
        await tester.pumpAndSettle();

        // Verify flag review status is reviewed for mock-001
        final flag001 = flagRepo.allFlags.firstWhere(
          (f) => f.reportId == 'mock-001',
        );
        expect(flag001.reviewStatus, FlagReviewStatus.reviewed);

        // Verify report moderationStatus is hidden
        final report001 = repo.getReportById('mock-001')!;
        expect(report001.moderationStatus, ModerationStatus.hidden);

        // 5. Laporan yang disembunyikan tidak lagi muncul di feed publik
        final publicReports = repo.getPublicReports();
        expect(publicReports.any((r) => r.id == 'mock-001'), isFalse);

        // 6. Admin dapat menampilkan kembali laporan yang disembunyikan
        await tester.tap(find.text('Disembunyikan'));
        await tester.pumpAndSettle();

        expect(find.text('Dompet hitam'), findsWidgets);

        // Tap 'Tampilkan'
        final tampilkanFinder = find.widgetWithText(FilledButton, 'Tampilkan');
        expect(tampilkanFinder, findsWidgets);
        await tester.tap(tampilkanFinder.first);
        await tester.pump();

        expect(
          find.text('Laporan kini ditampilkan ke publik.'),
          findsOneWidget,
        );
        await tester.pumpAndSettle();

        // Verify report moderationStatus is visible again
        final restoredReport = repo.getReportById('mock-001')!;
        expect(restoredReport.moderationStatus, ModerationStatus.visible);

        // Verify report appears again in public reports
        expect(repo.getPublicReports().any((r) => r.id == 'mock-001'), isTrue);
      },
    );

    testWidgets(
      'Admin hides report from Semua Laporan and resolves related open flags',
      (tester) async {
        final auth = MockAuthService();
        final repo = MockReportRepository();
        final flagRepo = MockFlagRepository();

        auth.login(email: 'admin@unsrat.ac.id', password: 'password123');
        auth.toggleAdminMode();

        // Open flag exists for mock-001 (seeded flag-001)
        expect(
          flagRepo.allFlags.any(
            (f) =>
                f.reportId == 'mock-001' &&
                f.reviewStatus == FlagReviewStatus.open,
          ),
          isTrue,
        );

        await tester.pumpWidget(
          FoundItApp(
            repository: repo,
            authService: auth,
            flagRepository: flagRepo,
          ),
        );
        await tester.pumpAndSettle();

        final navState = tester.state<NavigatorState>(find.byType(Navigator));
        navState.push(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        await tester.pumpAndSettle();

        // On tab 'Semua Laporan', find 'Dompet hitam' (mock-001)
        expect(find.text('Dompet hitam'), findsWidgets);

        // Find the 'Sembunyikan' button for mock-001
        final sembunyikanBtn = find
            .widgetWithText(OutlinedButton, 'Sembunyikan')
            .first;
        await tester.tap(sembunyikanBtn);
        await tester.pumpAndSettle();

        // Verify report is hidden
        expect(
          repo.getReportById('mock-001')!.moderationStatus,
          ModerationStatus.hidden,
        );

        // Verify open flags for mock-001 were resolved to reviewed
        final flag001 = flagRepo.allFlags.firstWhere(
          (f) => f.reportId == 'mock-001',
        );
        expect(flag001.reviewStatus, FlagReviewStatus.reviewed);
      },
    );
  });
}
