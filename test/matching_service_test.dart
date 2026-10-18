import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/core/constants/report_enums.dart';
import 'package:foundit/core/services/matching_service.dart';
import 'package:foundit/data/mock/mock_reports.dart';
import 'package:foundit/data/models/report.dart';

void main() {
  group('MatchingService Unit Tests', () {
    final now = DateTime.now();

    test('Category scoring: same category gives 30, different gives 0', () {
      final lost = Report(
        id: '1',
        ownerId: 'u1',
        reportType: ReportType.lost,
        itemName: 'Barang A',
        category: 'electronics_gadgets',
        campusArea: 'Area A',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final foundSameCategory = Report(
        id: '2',
        ownerId: 'u2',
        reportType: ReportType.found,
        itemName: 'Barang B',
        category: 'electronics_gadgets',
        campusArea: 'Area B',
        eventDate: now.subtract(const Duration(days: 20)),
        createdAt: now,
        updatedAt: now,
      );

      final foundDiffCategory = Report(
        id: '3',
        ownerId: 'u3',
        reportType: ReportType.found,
        itemName: 'Barang B',
        category: 'keys_access',
        campusArea: 'Area B',
        eventDate: now.subtract(const Duration(days: 20)),
        createdAt: now,
        updatedAt: now,
      );

      final scoreSame = MatchingService.calculateScore(lost, foundSameCategory);
      final scoreDiff = MatchingService.calculateScore(lost, foundDiffCategory);

      expect(scoreSame.categoryScore, equals(30));
      expect(scoreDiff.categoryScore, equals(0));
    });

    test('Location scoring: same area gives 15, same building gives 25', () {
      final lost = Report(
        id: '1',
        ownerId: 'u1',
        reportType: ReportType.lost,
        itemName: 'Barang A',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        buildingName: 'Gedung Kuliah Teknik',
        eventDate: now.subtract(const Duration(days: 10)),
        createdAt: now,
        updatedAt: now,
      );

      final foundSameBuilding = Report(
        id: '2',
        ownerId: 'u2',
        reportType: ReportType.found,
        itemName: 'Barang B',
        category: 'wallet_money',
        campusArea: 'Fakultas Teknik',
        buildingName: 'Gedung Kuliah Teknik',
        eventDate: now.subtract(const Duration(days: 10)),
        createdAt: now,
        updatedAt: now,
      );

      final foundSameAreaOnly = Report(
        id: '3',
        ownerId: 'u3',
        reportType: ReportType.found,
        itemName: 'Barang C',
        category: 'wallet_money',
        campusArea: 'Fakultas Teknik',
        buildingName: 'Workshop Mesin',
        eventDate: now.subtract(const Duration(days: 10)),
        createdAt: now,
        updatedAt: now,
      );

      final foundDiffArea = Report(
        id: '4',
        ownerId: 'u4',
        reportType: ReportType.found,
        itemName: 'Barang D',
        category: 'wallet_money',
        campusArea: 'Fakultas Kedokteran',
        buildingName: 'Gedung Kuliah FK',
        eventDate: now.subtract(const Duration(days: 10)),
        createdAt: now,
        updatedAt: now,
      );

      expect(
        MatchingService.calculateScore(lost, foundSameBuilding).locationScore,
        equals(25),
      );
      expect(
        MatchingService.calculateScore(lost, foundSameAreaOnly).locationScore,
        equals(15),
      );
      expect(
        MatchingService.calculateScore(lost, foundDiffArea).locationScore,
        equals(0),
      );
    });

    test(
      'Date scoring: 0 days gives 15, 1-3 gives 10, 4-7 gives 5, >7 gives 0',
      () {
        Report createWithDate(DateTime date) => Report(
          id: 'r',
          ownerId: 'u',
          reportType: ReportType.found,
          itemName: 'X',
          category: 'other',
          campusArea: 'Area',
          eventDate: date,
          createdAt: now,
          updatedAt: now,
        );

        final base = Report(
          id: 'base',
          ownerId: 'u',
          reportType: ReportType.lost,
          itemName: 'X',
          category: 'other',
          campusArea: 'Area',
          eventDate: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(
          MatchingService.calculateScore(base, createWithDate(now)).dateScore,
          equals(15),
        );
        expect(
          MatchingService.calculateScore(
            base,
            createWithDate(now.subtract(const Duration(days: 2))),
          ).dateScore,
          equals(10),
        );
        expect(
          MatchingService.calculateScore(
            base,
            createWithDate(now.subtract(const Duration(days: 5))),
          ).dateScore,
          equals(5),
        );
        expect(
          MatchingService.calculateScore(
            base,
            createWithDate(now.subtract(const Duration(days: 10))),
          ).dateScore,
          equals(0),
        );
      },
    );

    test('Keyword scoring: shared title keywords give up to 30 points', () {
      final lost = Report(
        id: '1',
        ownerId: 'u1',
        reportType: ReportType.lost,
        itemName: 'KTM Unsrat warna biru',
        description: 'Jatuh saat jam kuliah siang',
        category: 'cards_documents',
        campusArea: 'Area A',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final foundTitleMatch = Report(
        id: '2',
        ownerId: 'u2',
        reportType: ReportType.found,
        itemName: 'KTM mahasiswa biru',
        description: 'Ditemukan siang hari di koridor',
        category: 'cards_documents',
        campusArea: 'Area B',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final foundNoKeywordMatch = Report(
        id: '3',
        ownerId: 'u3',
        reportType: ReportType.found,
        itemName: 'Sepatu lari hitam',
        description: 'Merk tidak jelas',
        category: 'clothing_equipment',
        campusArea: 'Area B',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final matchScore = MatchingService.calculateScore(lost, foundTitleMatch);
      final noMatchScore = MatchingService.calculateScore(
        lost,
        foundNoKeywordMatch,
      );

      expect(matchScore.keywordScore, greaterThanOrEqualTo(20));
      expect(noMatchScore.keywordScore, equals(0));
    });

    test('High confidence matching pair meets or exceeds 60 threshold', () {
      final lostKtm = Report(
        id: 'lost-ktm',
        ownerId: 'u1',
        reportType: ReportType.lost,
        itemName: 'KTM Unsrat biru',
        description: 'KTM mahasiswa Fakultas Teknik Unsrat warna biru',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        buildingName: 'Gedung Kuliah Teknik',
        eventDate: now.subtract(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      );

      final foundKtm = Report(
        id: 'found-ktm',
        ownerId: 'u2',
        reportType: ReportType.found,
        itemName: 'KTM Mahasiswa Teknik',
        description: 'Ditemukan KTM biru mahasiswa Unsrat di lorong kelas',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        buildingName: 'Gedung Kuliah Teknik',
        eventDate: now.subtract(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      );

      final breakdown = MatchingService.calculateScore(lostKtm, foundKtm);
      expect(breakdown.isMatch, isTrue);
      expect(breakdown.totalScore, greaterThanOrEqualTo(60));
      expect(breakdown.categoryScore, equals(30));
      expect(breakdown.keywordScore, equals(30));
      expect(breakdown.locationScore, equals(25));
      expect(breakdown.dateScore, equals(15));
      expect(breakdown.totalScore, equals(100)); // 30 + 30 + 25 + 15
    });

    test('Non-matching pair falls below 60 threshold', () {
      final lostBackpack = Report(
        id: 'lost-bag',
        ownerId: 'u1',
        reportType: ReportType.lost,
        itemName: 'Tas ransel biru',
        category: 'bags_pouches',
        campusArea: 'Fakultas Ekonomi dan Bisnis',
        buildingName: 'Gedung Kuliah FEB',
        eventDate: now.subtract(const Duration(days: 12)),
        createdAt: now,
        updatedAt: now,
      );

      final foundKey = Report(
        id: 'found-key',
        ownerId: 'u2',
        reportType: ReportType.found,
        itemName: 'Kunci motor Yamaha',
        category: 'keys_access',
        campusArea: 'Area Umum Kampus',
        buildingName: 'Parkiran Utama',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final breakdown = MatchingService.calculateScore(lostBackpack, foundKey);
      expect(breakdown.isMatch, isFalse);
      expect(breakdown.totalScore, lessThan(60));
    });

    test(
      'findMatches identifies at least two matching pairs from kMockReports',
      () {
        final matches = MatchingService.findMatches(kMockReports);

        // Must find at least 2 realistic matches
        expect(matches.length, greaterThanOrEqualTo(2));

        for (final match in matches) {
          expect(match.lost.reportType, equals(ReportType.lost));
          expect(match.found.reportType, equals(ReportType.found));
          expect(match.score, greaterThanOrEqualTo(60));
        }

        // Check that sorting is descending
        for (int i = 0; i < matches.length - 1; i++) {
          expect(matches[i].score, greaterThanOrEqualTo(matches[i + 1].score));
        }
      },
    );
  });
}
