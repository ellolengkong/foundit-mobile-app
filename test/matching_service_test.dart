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

    test('extractKeywords: removes punctuation, filters stop words and words < 3 chars', () {
      // Punctuation & alphanumeric handling
      expect(
        MatchingService.extractKeywords('Tas-ransel (biru/hitam), model #123!'),
        equals({'tas', 'ransel', 'biru', 'hitam', 'model', '123'}),
      );

      // Stop words filtering
      expect(
        MatchingService.extractKeywords('KTM yang ada di dan untuk kampus'),
        equals({'ktm', 'kampus'}),
      );

      // Short words (< 3 chars) like "HP" are excluded
      expect(MatchingService.extractKeywords('HP'), isEmpty);
      expect(
        MatchingService.extractKeywords('HP Samsung di lab'),
        equals({'samsung', 'lab'}),
      );

      // Empty or whitespace strings
      expect(MatchingService.extractKeywords(''), isEmpty);
      expect(MatchingService.extractKeywords('   '), isEmpty);
    });

    test(
      'Keyword scoring: null description is handled safely without throwing',
      () {
        final lost = Report(
          id: 'lost-null-desc',
          ownerId: 'u1',
          reportType: ReportType.lost,
          itemName: 'KTM Unsrat',
          description: null,
          category: 'cards_documents',
          campusArea: 'Area A',
          eventDate: now,
          createdAt: now,
          updatedAt: now,
        );

        final found = Report(
          id: 'found-null-desc',
          ownerId: 'u2',
          reportType: ReportType.found,
          itemName: 'KTM Mahasiswa',
          description: null,
          category: 'cards_documents',
          campusArea: 'Area A',
          eventDate: now,
          createdAt: now,
          updatedAt: now,
        );

        final breakdown = MatchingService.calculateScore(lost, found);
        // Shared title keyword: 'ktm' (1 word).
        // Base score = 20, extraTitleWords = 0, additionalShared = 0.
        expect(breakdown.keywordScore, equals(20));
      },
    );

    test('Keyword scoring: description keyword overlap without title match gives up to 20 points', () {
      // Title words do not match:
      // Lost title keywords: {"flashdisk", "merah"}
      // Found title keywords: {"usb", "drive"}
      // Title intersection is empty -> sharedTitle.isEmpty branch executed.
      // Descriptions contain common keywords: "Kingston 32GB" -> {"kingston", "32gb"}
      // Lost all: {"flashdisk", "merah", "kingston", "32gb", "hilang"}
      // Found all: {"usb", "drive", "kingston", "32gb", "ditemukan"}
      // sharedAll: {"kingston", "32gb"} (2 words)
      // Score: (2 * 10).clamp(0, 20) = 20.
      final lost = Report(
        id: 'lost-desc-overlap',
        ownerId: 'u1',
        reportType: ReportType.lost,
        itemName: 'Flashdisk merah',
        description: 'Kingston 32GB hilang saat kuliah',
        category: 'electronics_gadgets',
        campusArea: 'Fakultas Teknik',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final found2Words = Report(
        id: 'found-desc-2words',
        ownerId: 'u2',
        reportType: ReportType.found,
        itemName: 'USB drive',
        description: 'Kingston 32GB ditemukan di meja',
        category: 'electronics_gadgets',
        campusArea: 'Fakultas Teknik',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final found1Word = Report(
        id: 'found-desc-1word',
        ownerId: 'u3',
        reportType: ReportType.found,
        itemName: 'USB drive',
        description: 'Kingston ditemukan di meja',
        category: 'electronics_gadgets',
        campusArea: 'Fakultas Teknik',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final score2Words = MatchingService.calculateScore(lost, found2Words);
      expect(score2Words.keywordScore, equals(20));
      // Capped at 20, cannot reach maxKeywordScore of 30 without title match
      expect(
        score2Words.keywordScore,
        lessThan(MatchingService.maxKeywordScore),
      );

      final score1Word = MatchingService.calculateScore(lost, found1Word);
      expect(score1Word.keywordScore, equals(10));
    });

    test('Location scoring: specificLocation keyword match gives +5 when buildings differ', () {
      final lost = Report(
        id: 'lost-spec-loc',
        ownerId: 'u1',
        reportType: ReportType.lost,
        itemName: 'Buku Catatan',
        category: 'books_stationery',
        campusArea: 'Fakultas Teknik',
        buildingName: 'Gedung Kuliah Elektro',
        specificLocation: 'Lantai 3 dekat lift', // keywords: {'lantai', 'lift'}
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final foundWithSharedLocation = Report(
        id: 'found-spec-shared',
        ownerId: 'u2',
        reportType: ReportType.found,
        itemName: 'Buku Catatan',
        category: 'books_stationery',
        campusArea: 'Fakultas Teknik',
        buildingName: 'Gedung Kuliah Sipil', // different building
        specificLocation:
            'Lantai 3 lorong barat', // keywords: {'lantai', 'lorong', 'barat'}
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final foundWithoutSharedLocation = Report(
        id: 'found-spec-none',
        ownerId: 'u3',
        reportType: ReportType.found,
        itemName: 'Buku Catatan',
        category: 'books_stationery',
        campusArea: 'Fakultas Teknik',
        buildingName: 'Gedung Kuliah Sipil', // different building
        specificLocation: 'Basement parkir motor', // keywords: {'basement', 'parkir', 'motor'}
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // Same area (15) + specificLocation overlap 'lantai' (5) = 20
      final scoreShared = MatchingService.calculateScore(
        lost,
        foundWithSharedLocation,
      );
      expect(scoreShared.locationScore, equals(20));

      // Same area (15) + no specificLocation overlap (0) = 15
      final scoreNone = MatchingService.calculateScore(
        lost,
        foundWithoutSharedLocation,
      );
      expect(scoreNone.locationScore, equals(15));
    });

    test('Location scoring: campusArea "Tidak tahu" yields 0 points even if both reports match', () {
      final lost = Report(
        id: 'lost-unknown-area',
        ownerId: 'u1',
        reportType: ReportType.lost,
        itemName: 'Kunci Motor',
        category: 'keys_access',
        campusArea: 'Tidak tahu',
        buildingName: 'Gedung Kuliah',
        specificLocation: 'Lantai 1',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final found = Report(
        id: 'found-unknown-area',
        ownerId: 'u2',
        reportType: ReportType.found,
        itemName: 'Kunci Motor',
        category: 'keys_access',
        campusArea: 'Tidak tahu',
        buildingName: 'Gedung Kuliah',
        specificLocation: 'Lantai 1',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final breakdown = MatchingService.calculateScore(lost, found);
      // Even with identical campusArea ("Tidak tahu"), buildingName, and specificLocation,
      // sameArea check excludes "Tidak tahu", giving 0 points for location.
      expect(breakdown.locationScore, equals(0));
    });

    test('Date scoring: verifies exact boundary thresholds for 3 vs 4 days and 7 vs 8 days', () {
      Report createWithDate(DateTime date) => Report(
        id: 'r-date',
        ownerId: 'u',
        reportType: ReportType.found,
        itemName: 'Barang',
        category: 'other',
        campusArea: 'Area',
        eventDate: date,
        createdAt: now,
        updatedAt: now,
      );

      final base = Report(
        id: 'base-date',
        ownerId: 'u',
        reportType: ReportType.lost,
        itemName: 'Barang',
        category: 'other',
        campusArea: 'Area',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // 3 days diff -> <= 3 -> 10 points
      final score3Days = MatchingService.calculateScore(
        base,
        createWithDate(now.subtract(const Duration(days: 3))),
      );
      expect(score3Days.dateScore, equals(10));

      // 4 days diff -> 4..7 -> 5 points
      final score4Days = MatchingService.calculateScore(
        base,
        createWithDate(now.subtract(const Duration(days: 4))),
      );
      expect(score4Days.dateScore, equals(5));

      // 7 days diff -> 4..7 -> 5 points
      final score7Days = MatchingService.calculateScore(
        base,
        createWithDate(now.subtract(const Duration(days: 7))),
      );
      expect(score7Days.dateScore, equals(5));

      // 8 days diff -> > 7 -> 0 points
      final score8Days = MatchingService.calculateScore(
        base,
        createWithDate(now.subtract(const Duration(days: 8))),
      );
      expect(score8Days.dateScore, equals(0));
    });

    test('Threshold evaluation: score of 55 does not match, score of exactly 60 qualifies as match', () {
      final lost = Report(
        id: 'lost-threshold',
        ownerId: 'u1',
        reportType: ReportType.lost,
        itemName: 'Flashdisk merah',
        description: 'Kingston 32GB hilang',
        category: 'electronics_gadgets',
        campusArea: 'Fakultas Teknik',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // 5 days diff -> date score = 5.
      // category(30) + keyword(20) + location(0) + date(5) = 55
      final foundScore55 = Report(
        id: 'found-55',
        ownerId: 'u2',
        reportType: ReportType.found,
        itemName: 'USB drive',
        description: 'Kingston 32GB ditemukan',
        category: 'electronics_gadgets',
        campusArea: 'Fakultas Kedokteran',
        eventDate: now.subtract(const Duration(days: 5)),
        createdAt: now,
        updatedAt: now,
      );

      // 2 days diff -> date score = 10.
      // category(30) + keyword(20) + location(0) + date(10) = 60
      final foundScore60 = Report(
        id: 'found-60',
        ownerId: 'u3',
        reportType: ReportType.found,
        itemName: 'USB drive',
        description: 'Kingston 32GB ditemukan',
        category: 'electronics_gadgets',
        campusArea: 'Fakultas Kedokteran',
        eventDate: now.subtract(const Duration(days: 2)),
        createdAt: now,
        updatedAt: now,
      );

      final breakdown55 = MatchingService.calculateScore(lost, foundScore55);
      expect(breakdown55.categoryScore, equals(30));
      expect(breakdown55.keywordScore, equals(20));
      expect(breakdown55.locationScore, equals(0));
      expect(breakdown55.dateScore, equals(5));
      expect(breakdown55.totalScore, equals(55));
      expect(breakdown55.isMatch, isFalse);

      final breakdown60 = MatchingService.calculateScore(lost, foundScore60);
      expect(breakdown60.categoryScore, equals(30));
      expect(breakdown60.keywordScore, equals(20));
      expect(breakdown60.locationScore, equals(0));
      expect(breakdown60.dateScore, equals(10));
      expect(breakdown60.totalScore, equals(60));
      expect(breakdown60.isMatch, isTrue);

      // When filtered through findMatches, only the score 60 report is returned
      final matches = MatchingService.findMatches([
        lost,
        foundScore55,
        foundScore60,
      ]);
      expect(matches.length, equals(1));
      expect(matches.first.found.id, equals('found-60'));
      expect(matches.first.score, equals(60));
    });

    test('findMatches: returns empty list when given empty report list', () {
      final matches = MatchingService.findMatches([]);
      expect(matches, isEmpty);
    });

    test('findMatches: returns empty list when all reports are of the same type (all lost or all found)', () {
      final lostReport1 = Report(
        id: 'lost-1',
        ownerId: 'u1',
        reportType: ReportType.lost,
        itemName: 'KTM Unsrat biru',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final lostReport2 = Report(
        id: 'lost-2',
        ownerId: 'u2',
        reportType: ReportType.lost,
        itemName: 'KTM Unsrat biru',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // All lost -> no found reports to match against
      final matchesAllLost = MatchingService.findMatches([
        lostReport1,
        lostReport2,
      ]);
      expect(matchesAllLost, isEmpty);

      final foundReport1 = Report(
        id: 'found-1',
        ownerId: 'u1',
        reportType: ReportType.found,
        itemName: 'KTM Unsrat biru',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final foundReport2 = Report(
        id: 'found-2',
        ownerId: 'u2',
        reportType: ReportType.found,
        itemName: 'KTM Unsrat biru',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // All found -> no lost reports to match against
      final matchesAllFound = MatchingService.findMatches([
        foundReport1,
        foundReport2,
      ]);
      expect(matchesAllFound, isEmpty);
    });

    test('findMatches: excludes resolved and hidden reports from matching', () {
      final activeLost = Report(
        id: 'lost-active',
        ownerId: 'u1',
        reportType: ReportType.lost,
        itemName: 'KTM Unsrat biru',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        status: ReportStatus.active,
        moderationStatus: ModerationStatus.visible,
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final activeFound = Report(
        id: 'found-active',
        ownerId: 'u2',
        reportType: ReportType.found,
        itemName: 'KTM Unsrat biru',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        status: ReportStatus.active,
        moderationStatus: ModerationStatus.visible,
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final resolvedFound = Report(
        id: 'found-resolved',
        ownerId: 'u3',
        reportType: ReportType.found,
        itemName: 'KTM Unsrat biru',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        status: ReportStatus.resolved,
        moderationStatus: ModerationStatus.visible,
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final hiddenFound = Report(
        id: 'found-hidden',
        ownerId: 'u4',
        reportType: ReportType.found,
        itemName: 'KTM Unsrat biru',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        status: ReportStatus.active,
        moderationStatus: ModerationStatus.hidden,
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final resolvedLost = Report(
        id: 'lost-resolved',
        ownerId: 'u5',
        reportType: ReportType.lost,
        itemName: 'KTM Unsrat biru',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        status: ReportStatus.resolved,
        moderationStatus: ModerationStatus.visible,
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final hiddenLost = Report(
        id: 'lost-hidden',
        ownerId: 'u6',
        reportType: ReportType.lost,
        itemName: 'KTM Unsrat biru',
        category: 'cards_documents',
        campusArea: 'Fakultas Teknik',
        status: ReportStatus.active,
        moderationStatus: ModerationStatus.hidden,
        eventDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // Candidate pool with active, resolved, and hidden reports
      final matches = MatchingService.findMatches([
        activeLost,
        activeFound,
        resolvedFound,
        hiddenFound,
        resolvedLost,
        hiddenLost,
      ]);

      // Only the active & visible pair (lost-active, found-active) should match
      expect(matches.length, equals(1));
      expect(matches.first.lost.id, equals('lost-active'));
      expect(matches.first.found.id, equals('found-active'));

      // If only resolved or hidden reports exist, no matches returned
      final nonVisibleMatches = MatchingService.findMatches([
        resolvedLost,
        hiddenLost,
        resolvedFound,
        hiddenFound,
      ]);
      expect(nonVisibleMatches, isEmpty);
    });
  });
}
