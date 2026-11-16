import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/core/constants/report_enums.dart';
import 'package:foundit/data/mock/mock_report_repository.dart';
import 'package:foundit/data/models/report.dart';

void main() {
  group('MockReportRepository Tests', () {
    late MockReportRepository repository;

    setUp(() {
      repository = MockReportRepository();
    });

    test('Initializes with mock reports and returns public reports', () {
      final reports = repository.getPublicReports();
      expect(reports.isNotEmpty, isTrue);
      // Public feed may include resolved reports but never moderation-hidden ones.
      for (final r in reports) {
        expect(r.moderationStatus, ModerationStatus.visible);
      }
    });

    test('Filters public reports by ReportType', () {
      final lostReports = repository.getPublicReports(type: ReportType.lost);
      expect(lostReports.every((r) => r.reportType == ReportType.lost), isTrue);

      final foundReports = repository.getPublicReports(type: ReportType.found);
      expect(
        foundReports.every((r) => r.reportType == ReportType.found),
        isTrue,
      );
    });

    test('Filters public reports by event date range', () {
      final now = DateTime.now();
      // Only today
      final todayReports = repository.getPublicReports(
        startDate: DateTime(now.year, now.month, now.day),
        endDate: DateTime(now.year, now.month, now.day),
      );
      for (final r in todayReports) {
        expect(r.eventDate.year, equals(now.year));
        expect(r.eventDate.month, equals(now.month));
        expect(r.eventDate.day, equals(now.day));
      }

      // Past date range that excludes today
      final pastReports = repository.getPublicReports(
        startDate: now.subtract(const Duration(days: 4)),
        endDate: now.subtract(const Duration(days: 2)),
      );
      expect(pastReports.isNotEmpty, isTrue);
      for (final r in pastReports) {
        final daysDiff = now.difference(r.eventDate).inDays;
        expect(daysDiff, greaterThanOrEqualTo(1));
      }
    });

    test('Creates new report and notifies listeners', () {
      int notifyCount = 0;
      repository.addListener(() => notifyCount++);

      final newReport = Report(
        id: 'new-123',
        ownerId: 'user-001',
        reportType: ReportType.lost,
        itemName: 'Kacamata Hitam Rayban',
        category: 'personal_accessories',
        campusArea: 'Fakultas Teknik',
        eventDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      repository.createReport(newReport);

      expect(notifyCount, 1);
      final retrieved = repository.getReportById('new-123');
      expect(retrieved, isNotNull);
      expect(retrieved!.itemName, 'Kacamata Hitam Rayban');
      expect(repository.getPublicReports().first.id, 'new-123');
    });

    test('Resolved reports remain in the public feed', () {
      final firstReport = repository.getPublicReports().first;
      expect(firstReport.status, ReportStatus.active);

      repository.resolveReport(firstReport.id);

      final updated = repository.getReportById(firstReport.id);
      expect(updated!.status, ReportStatus.resolved);
      expect(
        repository.getPublicReports().any((r) => r.id == firstReport.id),
        isTrue,
      );
    });

    test('Moderation-hidden reports are excluded from the public feed', () {
      final reportId = repository.getPublicReports().first.id;

      repository.setModerationStatus(reportId, ModerationStatus.hidden);

      expect(
        repository.getPublicReports().any((r) => r.id == reportId),
        isFalse,
      );
    });

    test('Deletes report from repository', () {
      final firstReport = repository.allReports.first;
      repository.deleteReport(firstReport.id);
      expect(repository.getReportById(firstReport.id), isNull);
    });
  });
}
