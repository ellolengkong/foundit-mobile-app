import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/core/constants/report_enums.dart';
import 'package:foundit/core/services/report_repository.dart';
import 'package:foundit/data/mock/mock_report_repository.dart';
import 'package:foundit/data/models/report.dart';

void main() {
  group('Report Model & Supabase Serialization Tests', () {
    test('Report.fromMap parses public_reports view format (privacy preserving)', () {
      final viewData = {
        'id': 'rep-pub-1',
        'report_type': 'lost',
        'item_name': 'Kunci Motor Honda Beat',
        'category': 'keys',
        'description': 'Gantungan kunci merah',
        'campus_area': 'Fakultas Teknik',
        'building_name': 'Gedung Elektro',
        'specific_location': 'Lab Komputer Lt. 2',
        'event_date': '2026-10-24T10:00:00.000Z',
        'photo_path': 'rep-pub-1/photo',
        'status': 'active',
        'created_at': '2026-10-24T10:30:00.000Z',
        'updated_at': '2026-10-24T10:30:00.000Z',
      };

      final report = Report.fromMap(viewData);

      expect(report.id, 'rep-pub-1');
      // owner_id must default to empty string for public feed privacy
      expect(report.ownerId, '');
      expect(report.reportType, ReportType.lost);
      expect(report.itemName, 'Kunci Motor Honda Beat');
      expect(report.category, 'keys');
      expect(report.campusArea, 'Fakultas Teknik');
      expect(report.buildingName, 'Gedung Elektro');
      expect(report.specificLocation, 'Lab Komputer Lt. 2');
      expect(report.photoPath, 'rep-pub-1/photo');
      expect(report.status, ReportStatus.active);
      expect(report.moderationStatus, ModerationStatus.visible);
      expect(report.isPubliclyVisible, isTrue);
    });

    test('Report.fromMap parses reports table format with owner_id', () {
      final tableData = {
        'id': 'rep-user-2',
        'owner_id': 'user-uuid-123',
        'report_type': 'found',
        'item_name': 'Tumbler Hydro Flask',
        'category': 'other',
        'campus_area': 'Fakultas Kedokteran',
        'event_date': '2026-10-24T08:00:00.000Z',
        'status': 'active',
        'moderation_status': 'visible',
        'created_at': '2026-10-24T09:00:00.000Z',
        'updated_at': '2026-10-24T09:00:00.000Z',
      };

      final report = Report.fromMap(tableData);

      expect(report.id, 'rep-user-2');
      expect(report.ownerId, 'user-uuid-123');
      expect(report.reportType, ReportType.found);
      expect(report.itemName, 'Tumbler Hydro Flask');
      expect(report.moderationStatus, ModerationStatus.visible);
    });

    test('Report.toInsertMap omits server-generated and restricted columns', () {
      final report = Report(
        id: 'client-id-should-be-omitted',
        ownerId: 'client-owner-should-be-omitted',
        reportType: ReportType.lost,
        itemName: 'Dompet Kulit Cokelat',
        category: 'wallets',
        campusArea: 'Fakultas Hukum',
        buildingName: 'Auditorium',
        specificLocation: 'Kursi baris ke-3',
        eventDate: DateTime(2026, 10, 24, 14, 0),
        description: 'Ada kartu identitas mahasiswa',
        photoPath: null,
        status: ReportStatus.resolved, // Server default is 'active'
        moderationStatus: ModerationStatus.hidden, // Restricted column
        createdAt: DateTime(2026, 10, 20),
        updatedAt: DateTime(2026, 10, 20),
      );

      final insertMap = report.toInsertMap();

      // Allowed insert columns per PostgreSQL GRANT:
      expect(insertMap.containsKey('report_type'), isTrue);
      expect(insertMap['report_type'], 'lost');
      expect(insertMap.containsKey('item_name'), isTrue);
      expect(insertMap['item_name'], 'Dompet Kulit Cokelat');
      expect(insertMap.containsKey('category'), isTrue);
      expect(insertMap['category'], 'wallets');
      expect(insertMap.containsKey('campus_area'), isTrue);
      expect(insertMap['campus_area'], 'Fakultas Hukum');
      expect(insertMap.containsKey('building_name'), isTrue);
      expect(insertMap['building_name'], 'Auditorium');
      expect(insertMap.containsKey('specific_location'), isTrue);
      expect(insertMap.containsKey('event_date'), isTrue);
      expect(insertMap.containsKey('description'), isTrue);

      // Restricted columns MUST NOT be present in insertMap
      expect(insertMap.containsKey('id'), isFalse);
      expect(insertMap.containsKey('owner_id'), isFalse);
      expect(insertMap.containsKey('status'), isFalse);
      expect(insertMap.containsKey('moderation_status'), isFalse);
      expect(insertMap.containsKey('created_at'), isFalse);
      expect(insertMap.containsKey('updated_at'), isFalse);
    });

    test('Report.toUpdateMap includes status and updatable columns', () {
      final report = Report(
        id: 'rep-update-1',
        ownerId: 'user-001',
        reportType: ReportType.lost,
        itemName: 'Laptop Asus ROG',
        category: 'electronics',
        campusArea: 'Fakultas MIPA',
        eventDate: DateTime(2026, 10, 24),
        status: ReportStatus.resolved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updateMap = report.toUpdateMap();

      expect(updateMap['status'], 'resolved');
      expect(updateMap['item_name'], 'Laptop Asus ROG');
      expect(updateMap.containsKey('owner_id'), isFalse);
      expect(updateMap.containsKey('moderation_status'), isFalse);
      expect(updateMap.containsKey('id'), isFalse);
    });
  });

  group('ReportRepository Contract Tests', () {
    late ReportRepository repo;

    setUp(() {
      repo = MockReportRepository();
    });

    test('ReportRepository conforms to CRUD and ownership checks', () async {
      final now = DateTime.now();
      final newReport = Report(
        id: 'custom-rep-101',
        ownerId: 'user-xyz',
        reportType: ReportType.found,
        itemName: 'Helm KYT Hitam',
        category: 'other',
        campusArea: 'Rektorat',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // Create
      await repo.createReport(newReport);

      expect(repo.getReportById('custom-rep-101'), isNotNull);
      expect(repo.isUserReportOwner('custom-rep-101', 'user-xyz'), isTrue);
      expect(repo.isUserReportOwner('custom-rep-101', 'other-user'), isFalse);

      // Query & search
      final searchResults = repo.getPublicReports(query: 'helm');
      expect(searchResults.any((r) => r.id == 'custom-rep-101'), isTrue);

      // Update
      final updated = newReport.copyWith(itemName: 'Helm KYT Hitam Doff');
      await repo.updateReport(updated);
      expect(repo.getReportById('custom-rep-101')?.itemName, 'Helm KYT Hitam Doff');

      // Resolve and reopen
      await repo.resolveReport('custom-rep-101');
      expect(repo.getReportById('custom-rep-101')?.status, ReportStatus.resolved);

      await repo.reopenReport('custom-rep-101');
      expect(repo.getReportById('custom-rep-101')?.status, ReportStatus.active);

      // Delete
      await repo.deleteReport('custom-rep-101');
      expect(repo.getReportById('custom-rep-101'), isNull);
    });
  });
}
