import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/core/constants/report_enums.dart';
import 'package:foundit/data/mock/mock_flag_repository.dart';

void main() {
  group('MockFlagRepository Tests', () {
    late MockFlagRepository flagRepo;

    setUp(() {
      flagRepo = MockFlagRepository();
    });

    test('Initializes with seeded open mock flags', () {
      expect(flagRepo.allFlags.length, greaterThanOrEqualTo(2));
      expect(
        flagRepo.openFlags.every(
          (f) => f.reviewStatus == FlagReviewStatus.open,
        ),
        isTrue,
      );
    });

    test('Submits new flag successfully and notifies listeners', () {
      int notifyCount = 0;
      flagRepo.addListener(() => notifyCount++);

      final success = flagRepo.submitFlag(
        reportId: 'mock-002',
        reporterId: 'user-999',
        reason: FlagReason.falseInformation,
        details: 'Barang sudah diambil tapi laporan masih aktif.',
      );

      expect(success, isTrue);
      expect(notifyCount, 1);

      final added = flagRepo.allFlags.first;
      expect(added.reportId, 'mock-002');
      expect(added.reporterId, 'user-999');
      expect(added.reason, FlagReason.falseInformation);
      expect(added.reviewStatus, FlagReviewStatus.open);
    });

    test('Prevents duplicate flag by same reporter on same report', () {
      final first = flagRepo.submitFlag(
        reportId: 'mock-005',
        reporterId: 'user-001',
        reason: FlagReason.spam,
      );
      expect(first, isTrue);

      final duplicate = flagRepo.submitFlag(
        reportId: 'mock-005',
        reporterId: 'user-001',
        reason: FlagReason.inappropriate,
      );
      expect(duplicate, isFalse);
    });

    test('Admin actions: dismissFlag and reviewFlag', () {
      final flag = flagRepo.openFlags.first;
      expect(flag.reviewStatus, FlagReviewStatus.open);

      flagRepo.dismissFlag(flag.id);
      final dismissed = flagRepo.allFlags.firstWhere((f) => f.id == flag.id);
      expect(dismissed.reviewStatus, FlagReviewStatus.dismissed);

      flagRepo.reviewFlag(flag.id);
      final reviewed = flagRepo.allFlags.firstWhere((f) => f.id == flag.id);
      expect(reviewed.reviewStatus, FlagReviewStatus.reviewed);
    });

    test(
      'resolveFlagsForReport marks all open flags for report as reviewed',
      () {
        flagRepo.submitFlag(
          reportId: 'mock-test-01',
          reporterId: 'user-a',
          reason: FlagReason.spam,
        );
        flagRepo.submitFlag(
          reportId: 'mock-test-01',
          reporterId: 'user-b',
          reason: FlagReason.falseInformation,
        );

        final openFlagsBefore = flagRepo.allFlags
            .where(
              (f) =>
                  f.reportId == 'mock-test-01' &&
                  f.reviewStatus == FlagReviewStatus.open,
            )
            .length;
        expect(openFlagsBefore, 2);

        flagRepo.resolveFlagsForReport(
          'mock-test-01',
          status: FlagReviewStatus.reviewed,
        );

        final openFlagsAfter = flagRepo.allFlags
            .where(
              (f) =>
                  f.reportId == 'mock-test-01' &&
                  f.reviewStatus == FlagReviewStatus.open,
            )
            .length;
        expect(openFlagsAfter, 0);

        final reviewedCount = flagRepo.allFlags
            .where(
              (f) =>
                  f.reportId == 'mock-test-01' &&
                  f.reviewStatus == FlagReviewStatus.reviewed,
            )
            .length;
        expect(reviewedCount, 2);
      },
    );
  });
}
