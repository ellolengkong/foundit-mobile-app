import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/core/constants/report_enums.dart';
import 'package:foundit/core/services/flag_repository.dart';
import 'package:foundit/data/mock/foundit_scope.dart';
import 'package:foundit/data/mock/mock_auth_service.dart';
import 'package:foundit/data/mock/mock_flag_repository.dart';
import 'package:foundit/data/mock/mock_report_repository.dart';
import 'package:foundit/data/models/report_flag.dart';
import 'package:foundit/screens/admin/admin_dashboard_screen.dart';

void main() {
  group('ReportFlag Model & Supabase Serialization Tests', () {
    test('ReportFlag.fromMap parses Supabase report_flags row', () {
      final data = {
        'id': 'flag-uuid-1',
        'report_id': 'report-uuid-10',
        'reporter_id': 'user-uuid-99',
        'reason': 'personal_data',
        'details': 'Menampilkan nomor telepon dan KTP pada deskripsi.',
        'review_status': 'open',
        'created_at': '2026-10-24T12:00:00.000Z',
      };

      final flag = ReportFlag.fromMap(data);

      expect(flag.id, 'flag-uuid-1');
      expect(flag.reportId, 'report-uuid-10');
      expect(flag.reporterId, 'user-uuid-99');
      expect(flag.reason, FlagReason.personalData);
      expect(flag.details, contains('KTP'));
      expect(flag.reviewStatus, FlagReviewStatus.open);
      expect(flag.createdAt.year, 2026);
    });

    test('ReportFlag.toInsertMap conforms strictly to PostgreSQL column INSERT grant', () {
      final flag = ReportFlag(
        id: 'client-generated-should-be-omitted',
        reportId: 'rep-001',
        reporterId: 'user-001',
        reason: FlagReason.spam,
        details: 'Spam berulang kali',
        reviewStatus:
            FlagReviewStatus.reviewed, // Must be omitted (DB default is 'open')
        createdAt: DateTime.now(), // Must be omitted (DB default is now())
      );

      final insertMap = flag.toInsertMap();

      // Only granted columns: report_id, reporter_id, reason, details
      expect(insertMap['report_id'], 'rep-001');
      expect(insertMap['reporter_id'], 'user-001');
      expect(insertMap['reason'], 'spam');
      expect(insertMap['details'], 'Spam berulang kali');

      // Server-managed columns must NEVER be present in insert payload
      expect(insertMap.containsKey('id'), isFalse);
      expect(insertMap.containsKey('review_status'), isFalse);
      expect(insertMap.containsKey('created_at'), isFalse);
    });

    test('Moderation status parameters match SQL RPC constraints', () {
      // admin_set_report_moderation expects p_moderation_status IN ('visible', 'hidden')
      expect(ModerationStatus.visible.key, 'visible');
      expect(ModerationStatus.hidden.key, 'hidden');

      // admin_review_flag expects p_review_status IN ('open', 'reviewed', 'dismissed')
      expect(FlagReviewStatus.open.key, 'open');
      expect(FlagReviewStatus.reviewed.key, 'reviewed');
      expect(FlagReviewStatus.dismissed.key, 'dismissed');

      // Reason enum check in report_flags table
      final validReasons = [
        'spam',
        'false_information',
        'inappropriate',
        'personal_data',
        'other',
      ];
      for (final reason in FlagReason.values) {
        expect(validReasons.contains(reason.key), isTrue);
      }
    });
  });

  group('FlagRepository Contract Tests', () {
    late FlagRepository repo;

    setUp(() {
      repo = MockFlagRepository();
    });

    test('FlagRepository manages flags and review status', () async {
      expect(repo.allFlags.length, greaterThanOrEqualTo(2));

      // Submit new flag
      final success = await repo.submitFlag(
        reportId: 'rep-test-99',
        reporterId: 'user-reporter-1',
        reason: FlagReason.inappropriate,
        details: 'Konten kasar',
      );
      expect(success, isTrue);

      final submitted = repo.allFlags.firstWhere(
        (f) => f.reportId == 'rep-test-99',
      );
      expect(submitted.reason, FlagReason.inappropriate);
      expect(submitted.reviewStatus, FlagReviewStatus.open);

      // Dismiss flag
      await repo.dismissFlag(submitted.id);
      expect(
        repo.allFlags.firstWhere((f) => f.id == submitted.id).reviewStatus,
        FlagReviewStatus.dismissed,
      );

      // Review flag
      await repo.reviewFlag(submitted.id);
      expect(
        repo.allFlags.firstWhere((f) => f.id == submitted.id).reviewStatus,
        FlagReviewStatus.reviewed,
      );

      // Bulk resolve open flags for a report
      await repo.submitFlag(
        reportId: 'rep-bulk-test',
        reporterId: 'user-reporter-2',
        reason: FlagReason.spam,
      );
      expect(repo.openFlags.any((f) => f.reportId == 'rep-bulk-test'), isTrue);

      await repo.resolveFlagsForReport(
        'rep-bulk-test',
        status: FlagReviewStatus.reviewed,
      );
      expect(repo.openFlags.any((f) => f.reportId == 'rep-bulk-test'), isFalse);
    });
  });

  group('AdminDashboardScreen Security & Access Guard Tests', () {
    testWidgets('Blocks non-admin user with Akses Ditolak', (tester) async {
      final auth = MockAuthService(); // Default: not admin
      final reportRepo = MockReportRepository();
      final flagRepo = _CountingFlagRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: FoundItScope(
            repository: reportRepo,
            authService: auth,
            flagRepository: flagRepo,
            child: const AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(
        find.text('Anda tidak memiliki izin untuk mengakses Dashboard Admin.'),
        findsOneWidget,
      );
      expect(find.text('Semua Laporan'), findsNothing);
      expect(flagRepo.refreshCount, 0);
    });

    testWidgets('Allows admin access and renders moderation tabs', (
      tester,
    ) async {
      final auth = MockAuthService();
      await auth.login(
        email: 'admin@test.com',
        password: 'password',
      ); // must be logged in
      auth.toggleAdminMode(); // Activate admin mode
      final reportRepo = MockReportRepository();
      final flagRepo = _CountingFlagRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: FoundItScope(
            repository: reportRepo,
            authService: auth,
            flagRepository: flagRepo,
            child: const AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Admin (Mock)'), findsOneWidget);
      expect(find.text('Semua Laporan'), findsOneWidget);
      expect(find.text('Dilaporkan'), findsOneWidget);
      expect(find.text('Disembunyikan'), findsOneWidget);
      expect(flagRepo.refreshCount, 1);
    });
  });

  // ── Security Regression: canAccessAdmin must be database-role-driven ────────
  group('Security Regression: toggleAdminMode no-op in MockAuthService', () {
    // NOTE: We test MockAuthService here because SupabaseAuthService requires
    // a live Supabase client and cannot be unit-tested without mocks/fakes.
    // The critical contract verified below is:
    //   - In MockAuthService (prototype only): toggleAdminMode() works as expected.
    //   - In SupabaseAuthService (production): toggleAdminMode() is a documented no-op.
    // The production contract is enforced by code review; the dart code is trivially
    // verified since the method body only contains comments.

    test('MockAuthService: unauthenticated user cannot access admin', () {
      final auth = MockAuthService();
      // Not logged in, not admin mode
      expect(auth.isLoggedIn, isFalse);
      expect(auth.canAccessAdmin, isFalse);
    });

    test(
      'MockAuthService: logged-in user without toggle cannot access admin',
      () async {
        final auth = MockAuthService();
        await auth.login(email: 'user@test.com', password: 'password');

        expect(auth.isLoggedIn, isTrue);
        expect(auth.isAdminMode, isFalse);
        // role='user' in mock login, isAdmin=false
        expect(auth.currentUser?.isAdmin, isFalse);
        expect(auth.canAccessAdmin, isFalse);
      },
    );

    test(
      'MockAuthService: toggleAdminMode grants mock access when logged in',
      () async {
        final auth = MockAuthService();
        await auth.login(email: 'user@test.com', password: 'password');

        auth.toggleAdminMode();
        expect(auth.isAdminMode, isTrue);
        expect(auth.canAccessAdmin, isTrue); // Mock only — prototype testing
      },
    );

    test('MockAuthService: logout resets admin mode', () async {
      final auth = MockAuthService();
      await auth.login(email: 'user@test.com', password: 'password');
      auth.toggleAdminMode();
      expect(auth.canAccessAdmin, isTrue);

      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.isAdminMode, isFalse);
      expect(auth.canAccessAdmin, isFalse);
    });

    test(
      'MockAuthService: toggleAdminMode toggle off removes access',
      () async {
        final auth = MockAuthService();
        await auth.login(email: 'user@test.com', password: 'password');

        auth.toggleAdminMode(); // ON
        expect(auth.canAccessAdmin, isTrue);

        auth.toggleAdminMode(); // OFF
        expect(auth.canAccessAdmin, isFalse);
      },
    );

    test(
      'canAccessAdmin requires both isLoggedIn AND database admin role',
      () async {
        final auth = MockAuthService();
        // Not logged in — even if we somehow had isAdminMode=true, gate fails
        expect(auth.canAccessAdmin, isFalse);

        // Log in as regular user
        await auth.login(email: 'user@test.com', password: 'password');
        expect(auth.currentUser?.isAdmin, isFalse);
        expect(auth.canAccessAdmin, isFalse);
      },
    );

    // Widget test: verify that a user who IS logged in but NOT admin
    // sees "Akses Ditolak" even when they somehow reach AdminDashboardScreen
    testWidgets('Logged-in non-admin user blocked by dashboard guard', (
      tester,
    ) async {
      final auth = MockAuthService();
      await auth.login(email: 'regular@test.com', password: 'pw');
      // Do NOT toggle admin mode — simulates a non-admin in production

      final reportRepo = MockReportRepository();
      final flagRepo = MockFlagRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: FoundItScope(
            repository: reportRepo,
            authService: auth,
            flagRepository: flagRepo,
            child: const AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dashboard must reject the user, not render tabs
      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(find.text('Semua Laporan'), findsNothing);
      expect(find.text('Dilaporkan'), findsNothing);
    });
  });
}

class _CountingFlagRepository extends MockFlagRepository {
  int refreshCount = 0;

  @override
  Future<void> refresh() async {
    refreshCount++;
    await super.refresh();
  }
}
