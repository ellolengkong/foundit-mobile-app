import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/core/constants/categories.dart';
import 'package:foundit/core/constants/locations.dart';
import 'package:foundit/core/constants/report_enums.dart';
import 'package:foundit/data/mock/mock_reports.dart';

void main() {
  group('DATA_MODEL.md Compliance Tests', () {
    test('ReportType matches DATA_MODEL.md §5.1', () {
      expect(ReportType.values.map((e) => e.key).toSet(), {'lost', 'found'});
      expect(ReportType.lost.label, 'Barang Hilang');
      expect(ReportType.found.label, 'Barang Ditemukan');
    });

    test('ReportStatus matches DATA_MODEL.md §4.3', () {
      expect(ReportStatus.values.map((e) => e.key).toSet(), {
        'active',
        'resolved',
      });
    });

    test('ModerationStatus matches DATA_MODEL.md §4.3', () {
      expect(ModerationStatus.values.map((e) => e.key).toSet(), {
        'visible',
        'hidden',
      });
    });

    test('FlagReason matches DATA_MODEL.md §4.4', () {
      expect(FlagReason.values.map((e) => e.key).toSet(), {
        'spam',
        'false_information',
        'inappropriate',
        'personal_data',
        'other',
      });
    });

    test('FlagReviewStatus matches DATA_MODEL.md §4.4', () {
      expect(FlagReviewStatus.values.map((e) => e.key).toSet(), {
        'open',
        'reviewed',
        'dismissed',
      });
    });

    test('ItemCategory matches the 10 exact keys in DATA_MODEL.md §5.2', () {
      const expectedKeys = [
        'electronics_gadgets',
        'wallet_money',
        'cards_documents',
        'keys_access',
        'bags_pouches',
        'books_stationery',
        'clothing_equipment',
        'personal_accessories',
        'bottles_food_containers',
        'other',
      ];

      expect(kCategories.length, 10);
      expect(kCategories.map((c) => c.key).toList(), expectedKeys);

      for (final key in expectedKeys) {
        expect(categoryByKey(key), isNotNull);
        expect(categoryByKey(key)!.label.isNotEmpty, isTrue);
      }
    });

    test('CampusArea matches DATA_MODEL.md §5.3 requirements', () {
      expect(kCampusAreas.contains('Area Umum Kampus'), isTrue);
      expect(kCampusAreas.contains('Lainnya'), isTrue);
      expect(kCampusAreas.contains('Tidak tahu'), isTrue);
      expect(kCampusAreas.contains('Fakultas Kedokteran'), isTrue);
      expect(kCampusAreas.contains('Fakultas Teknik'), isTrue);
      expect(kCampusAreas.contains('Fakultas Pertanian'), isTrue);
      expect(kCampusAreas.contains('Fakultas Peternakan'), isTrue);
      expect(
        kCampusAreas.contains('Fakultas Perikanan dan Ilmu Kelautan'),
        isTrue,
      );
      expect(kCampusAreas.contains('Fakultas Ekonomi dan Bisnis'), isTrue);
      expect(kCampusAreas.contains('Fakultas Hukum'), isTrue);
      expect(
        kCampusAreas.contains('Fakultas Matematika dan Ilmu Pengetahuan Alam'),
        isTrue,
      );
      expect(kCampusAreas.contains('Fakultas Ilmu Sosial dan Politik'), isTrue);
      expect(kCampusAreas.contains('Fakultas Ilmu Budaya'), isTrue);
      expect(kCampusAreas.contains('Fakultas Kesehatan Masyarakat'), isTrue);
      expect(kCampusAreas.contains('Pascasarjana'), isTrue);
    });

    test('Building names are identified as example data, with fallbacks', () {
      expect(kBuildingExampleDisclaimer.isNotEmpty, isTrue);

      // Specific sample buildings are identified as examples
      expect(isExampleBuilding('Gedung Kuliah Teknik'), isTrue);
      expect(isExampleBuilding('Perpustakaan Pusat'), isTrue);

      // Standard fallbacks are not labeled as fictitious examples
      expect(isExampleBuilding('Lainnya'), isFalse);
      expect(isExampleBuilding('Tidak tahu'), isFalse);
      expect(isExampleBuilding(null), isFalse);
      expect(isExampleBuilding(''), isFalse);
    });

    test('All mock reports strictly comply with DATA_MODEL.md keys & areas', () {
      final categoryKeys = kCategories.map((c) => c.key).toSet();
      final campusAreas = kCampusAreas.toSet();

      for (final report in kMockReports) {
        expect(
          categoryKeys.contains(report.category),
          isTrue,
          reason:
              'Report ${report.id} category ${report.category} not in kCategories',
        );
        expect(
          campusAreas.contains(report.campusArea),
          isTrue,
          reason:
              'Report ${report.id} campusArea ${report.campusArea} not in kCampusAreas',
        );
        expect(report.ownerId.isNotEmpty, isTrue);
        expect(report.itemName.isNotEmpty, isTrue);
      }
    });
  });
}
