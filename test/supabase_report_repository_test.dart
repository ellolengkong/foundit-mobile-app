import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/core/constants/report_enums.dart';
import 'package:foundit/core/services/report_repository.dart';
import 'package:foundit/data/mock/foundit_scope.dart';
import 'package:foundit/data/mock/mock_auth_service.dart';
import 'package:foundit/data/mock/mock_flag_repository.dart';
import 'package:foundit/data/mock/mock_report_repository.dart';
import 'package:foundit/data/models/report.dart';
import 'package:foundit/screens/report/create_report_screen.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

final kTransparent1x1Png = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class FakeImagePickerPlatform extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return XFile.fromData(
      kTransparent1x1Png,
      name: 'photo.png',
      mimeType: 'image/png',
    );
  }
}

void main() {
  group('Report Model & Supabase Serialization Tests', () {
    test(
      'Report.fromMap parses public_reports view format (privacy preserving)',
      () {
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
      },
    );

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

    test(
      'Report.toInsertMap omits server-generated and restricted columns',
      () {
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
      },
    );

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
      expect(
        repo.getReportById('custom-rep-101')?.itemName,
        'Helm KYT Hitam Doff',
      );

      // Resolve and reopen
      await repo.resolveReport('custom-rep-101');
      expect(
        repo.getReportById('custom-rep-101')?.status,
        ReportStatus.resolved,
      );

      await repo.reopenReport('custom-rep-101');
      expect(repo.getReportById('custom-rep-101')?.status, ReportStatus.active);

      // Delete
      await repo.deleteReport('custom-rep-101');
      expect(repo.getReportById('custom-rep-101'), isNull);
    });

    test(
      'createReport with photo bytes sets valid storage path on upload success',
      () async {
        final now = DateTime.now();
        final newReport = Report(
          id: 'rep-upload-success',
          ownerId: 'user-abc',
          reportType: ReportType.lost,
          itemName: 'Tas Ransel Hitam',
          category: 'bags',
          campusArea: 'Fakultas Teknik',
          eventDate: now,
          photoPath: null, // Initial report must not store temporary path
          createdAt: now,
          updatedAt: now,
        );

        final result = await repo.createReport(
          newReport,
          photoBytes: Uint8List.fromList([1, 2, 3]),
          photoMimeType: 'image/jpeg',
        );

        expect(result.photoPath, 'rep-upload-success/photo');
        expect(
          repo.getReportById('rep-upload-success')?.photoPath,
          'rep-upload-success/photo',
        );
      },
    );

    test('createReport with photo bytes leaves photoPath as null on upload failure', () async {
      final mockRepo = repo as MockReportRepository;
      mockRepo.simulatePhotoUploadFailure = true;

      final now = DateTime.now();
      final newReport = Report(
        id: 'rep-upload-fail',
        ownerId: 'user-abc',
        reportType: ReportType.lost,
        itemName: 'Kunci Loker',
        category: 'keys',
        campusArea: 'Fakultas MIPA',
        eventDate: now,
        photoPath: null,
        createdAt: now,
        updatedAt: now,
      );

      // When photo upload fails, report must still be created, but without photo_path
      final result = await mockRepo.createReport(
        newReport,
        photoBytes: Uint8List.fromList([1, 2, 3]),
        photoMimeType: 'image/jpeg',
      );

      expect(result.id, 'rep-upload-fail');
      expect(result.photoPath, isNull);
      expect(mockRepo.getReportById('rep-upload-fail')?.photoPath, isNull);
    });

    test(
      'updateReport with newPhotoBytes handles success and failure',
      () async {
        final mockRepo = repo as MockReportRepository;
        final now = DateTime.now();
        final report = Report(
          id: 'rep-update-photo',
          ownerId: 'user-abc',
          reportType: ReportType.lost,
          itemName: 'Buku Catatan',
          category: 'books',
          campusArea: 'Perpustakaan',
          eventDate: now,
          photoPath: null,
          createdAt: now,
          updatedAt: now,
        );

        await mockRepo.createReport(report);

        // Upload new photo success
        await mockRepo.updateReport(
          report,
          newPhotoBytes: Uint8List.fromList([4, 5, 6]),
        );
        expect(
          mockRepo.getReportById('rep-update-photo')?.photoPath,
          'rep-update-photo/photo',
        );

        // Upload failure
        mockRepo.simulatePhotoUploadFailure = true;
        await mockRepo.updateReport(
          report,
          newPhotoBytes: Uint8List.fromList([7, 8, 9]),
        );
        expect(mockRepo.getReportById('rep-update-photo')?.photoPath, isNull);
      },
    );
  });

  group('CreateReportScreen Photo Upload Tests', () {
    setUp(() {
      ImagePickerPlatform.instance = FakeImagePickerPlatform();
    });

    testWidgets(
      'CreateReportScreen creates report with valid storage path on photo upload success',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = MockAuthService();
        auth.login(email: 'alice@unsrat.ac.id', password: 'password123');
        final repo = MockReportRepository();
        final flagRepo = MockFlagRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: FoundItScope(
              authService: auth,
              repository: repo,
              flagRepository: flagRepo,
              child: const CreateReportScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Pick photo (activates test fallback with photo bytes)
        await tester.tap(
          find.text('Ketuk untuk memilih foto barang (Maks 1 MB)'),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.close), findsOneWidget);

        // 2. Fill required fields
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Contoh: KTM Biru, Dompet Kulit Cokelat',
          ),
          'KTM Mahasiswa Baru',
        );

        // Select category
        final categoryFinder = find.widgetWithText(
          DropdownButtonFormField<String>,
          'Pilih kategori barang',
        );
        await tester.ensureVisible(categoryFinder);
        await tester.tap(categoryFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kartu & Dokumen').last);
        await tester.pumpAndSettle();

        // Select campus area
        final areaFinder = find.widgetWithText(
          DropdownButtonFormField<String>,
          'Pilih area kampus',
        );
        await tester.ensureVisible(areaFinder);
        await tester.tap(areaFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Fakultas Teknik').last);
        await tester.pumpAndSettle();

        // 3. Submit
        final submitButton = find.text('Kirim Laporan');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        final created = repo.allReports.first;
        expect(created.itemName, 'KTM Mahasiswa Baru');
        // Photo path must be {report_id}/photo, NOT temporary '$ownerId/photo'
        expect(created.photoPath, '${created.id}/photo');
        expect(created.photoPath, isNot(contains(auth.currentUser!.id)));
      },
    );

    testWidgets(
      'CreateReportScreen still saves report with photoPath = null when photo upload fails',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = MockAuthService();
        auth.login(email: 'alice@unsrat.ac.id', password: 'password123');
        final repo = MockReportRepository();
        repo.simulatePhotoUploadFailure = true;
        final flagRepo = MockFlagRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: FoundItScope(
              authService: auth,
              repository: repo,
              flagRepository: flagRepo,
              child: const CreateReportScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Pick photo
        await tester.tap(
          find.text('Ketuk untuk memilih foto barang (Maks 1 MB)'),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.close), findsOneWidget);

        // 2. Fill required fields
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Contoh: KTM Biru, Dompet Kulit Cokelat',
          ),
          'Kacamata Minus Hilang',
        );

        // Select category
        final categoryFinder = find.widgetWithText(
          DropdownButtonFormField<String>,
          'Pilih kategori barang',
        );
        await tester.ensureVisible(categoryFinder);
        await tester.tap(categoryFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aksesori Pribadi').last);
        await tester.pumpAndSettle();

        // Select campus area
        final areaFinder = find.widgetWithText(
          DropdownButtonFormField<String>,
          'Pilih area kampus',
        );
        await tester.ensureVisible(areaFinder);
        await tester.tap(areaFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Fakultas Kedokteran').last);
        await tester.pumpAndSettle();

        // 3. Submit
        final submitButton = find.text('Kirim Laporan');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Report must still exist, but without non-existent photo path
        final created = repo.allReports.first;
        expect(created.itemName, 'Kacamata Minus Hilang');
        expect(created.photoPath, isNull);
        expect(created.status, ReportStatus.active);
      },
    );
  });
}
