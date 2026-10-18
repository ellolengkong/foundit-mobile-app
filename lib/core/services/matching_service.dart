import '../constants/report_enums.dart';
import '../../data/models/report.dart';

/// Detailed breakdown of deterministic matching score between two reports.
///
/// Follows PRD.md §4.6 and DATA_MODEL.md §6:
/// - Category match: 30 points
/// - Keyword similarity: up to 30 points
/// - Campus location: up to 25 points
/// - Event date proximity: up to 15 points
/// Total maximum: 100 points. Initial threshold: 60 points.
class MatchScoreBreakdown {
  const MatchScoreBreakdown({
    required this.categoryScore,
    required this.keywordScore,
    required this.locationScore,
    required this.dateScore,
  });

  final int categoryScore;
  final int keywordScore;
  final int locationScore;
  final int dateScore;

  int get totalScore =>
      categoryScore + keywordScore + locationScore + dateScore;

  bool get isMatch => totalScore >= MatchingService.threshold;
}

/// Represents a scored match pair between a lost report and a found report.
class MatchPair {
  const MatchPair({
    required this.lost,
    required this.found,
    required this.breakdown,
  });

  final Report lost;
  final Report found;
  final MatchScoreBreakdown breakdown;

  int get score => breakdown.totalScore;
}

/// Deterministic rule-based matching service.
class MatchingService {
  MatchingService._();

  /// Initial heuristic threshold for "Kemungkinan cocok" (PRD §4.6).
  static const int threshold = 60;

  static const int maxCategoryScore = 30;
  static const int maxKeywordScore = 30;
  static const int maxLocationScore = 25;
  static const int maxDateScore = 15;

  static final Set<String> _stopWords = {
    'yang',
    'dan',
    'di',
    'ke',
    'dari',
    'ini',
    'itu',
    'ada',
    'untuk',
    'pada',
    'dengan',
    'adalah',
    'atau',
    'warna',
    'dekat',
    'sekitar',
    'sebuah',
    'dalam',
    'bisa',
  };

  /// Tokenizes a text into lowercase normalized keywords, removing punctuation and stop words.
  static Set<String> extractKeywords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.length >= 3 && !_stopWords.contains(w))
        .toSet();
  }

  /// Calculates the heuristic match score breakdown between two reports.
  static MatchScoreBreakdown calculateScore(Report a, Report b) {
    // 1. Category Score (30 points)
    final int categoryScore = (a.category == b.category) ? maxCategoryScore : 0;

    // 2. Keyword Similarity Score (up to 30 points)
    final aTitleKeywords = extractKeywords(a.itemName);
    final bTitleKeywords = extractKeywords(b.itemName);

    final aAllKeywords = extractKeywords(
      '${a.itemName} ${a.description ?? ''}',
    );
    final bAllKeywords = extractKeywords(
      '${b.itemName} ${b.description ?? ''}',
    );

    int keywordScore = 0;
    // Shared title keyword match gives strong indication (20 pts)
    final sharedTitle = aTitleKeywords.intersection(bTitleKeywords);
    if (sharedTitle.isNotEmpty) {
      keywordScore += 20;
      // Additional shared words in title or description provide up to 10 more points
      final extraTitleWords = sharedTitle.length - 1;
      final additionalShared = aAllKeywords
          .intersection(bAllKeywords)
          .difference(sharedTitle);
      keywordScore += ((extraTitleWords + additionalShared.length) * 5).clamp(
        0,
        10,
      );
    } else {
      // Titles don't match exactly, but description mentions title word or descriptions overlap
      final sharedAll = aAllKeywords.intersection(bAllKeywords);
      if (sharedAll.isNotEmpty) {
        keywordScore += (sharedAll.length * 10).clamp(0, 20);
      }
    }
    keywordScore = keywordScore.clamp(0, maxKeywordScore);

    // 3. Location Score (up to 25 points)
    int locationScore = 0;
    final bool sameArea =
        a.campusArea == b.campusArea && a.campusArea != 'Tidak tahu';
    if (sameArea) {
      locationScore += 15;

      final aBuilding = a.buildingName;
      final bBuilding = b.buildingName;
      final bool validBuildingA =
          aBuilding != null &&
          aBuilding.isNotEmpty &&
          aBuilding != 'Tidak tahu' &&
          aBuilding != 'Lainnya';
      final bool validBuildingB =
          bBuilding != null &&
          bBuilding.isNotEmpty &&
          bBuilding != 'Tidak tahu' &&
          bBuilding != 'Lainnya';

      if (validBuildingA && validBuildingB && aBuilding == bBuilding) {
        locationScore += 10;
      } else if (a.specificLocation != null && b.specificLocation != null) {
        final aLocWords = extractKeywords(a.specificLocation!);
        final bLocWords = extractKeywords(b.specificLocation!);
        if (aLocWords.intersection(bLocWords).isNotEmpty) {
          locationScore += 5;
        }
      }
    }
    locationScore = locationScore.clamp(0, maxLocationScore);

    // 4. Date Proximity Score (up to 15 points)
    final daysDiff = (a.eventDate.difference(b.eventDate).inDays).abs();
    int dateScore;
    if (daysDiff == 0) {
      dateScore = 15;
    } else if (daysDiff <= 3) {
      dateScore = 10;
    } else if (daysDiff <= 7) {
      dateScore = 5;
    } else {
      dateScore = 0;
    }

    return MatchScoreBreakdown(
      categoryScore: categoryScore,
      keywordScore: keywordScore,
      locationScore: locationScore,
      dateScore: dateScore,
    );
  }

  /// Evaluates a list of public reports and returns potential matching pairs
  /// with score >= [threshold], sorted from highest score to lowest.
  static List<MatchPair> findMatches(List<Report> reports) {
    final activeVisibleReports = reports
        .where((r) => r.isPubliclyVisible)
        .toList();
    final lostReports = activeVisibleReports
        .where((r) => r.reportType == ReportType.lost)
        .toList();
    final foundReports = activeVisibleReports
        .where((r) => r.reportType == ReportType.found)
        .toList();

    final matches = <MatchPair>[];

    for (final lost in lostReports) {
      for (final found in foundReports) {
        final breakdown = calculateScore(lost, found);
        if (breakdown.isMatch) {
          matches.add(
            MatchPair(lost: lost, found: found, breakdown: breakdown),
          );
        }
      }
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }
}
