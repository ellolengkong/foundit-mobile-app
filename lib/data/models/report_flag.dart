import '../../core/constants/report_enums.dart';

/// Report abuse flag model from DATA_MODEL.md §4.4.
///
/// Records user reports of spam, inappropriate content, false information,
/// personal data exposure, or other issues.
class ReportFlag {
  const ReportFlag({
    required this.id,
    required this.reportId,
    required this.reporterId,
    required this.reason,
    this.details,
    this.reviewStatus = FlagReviewStatus.open,
    required this.createdAt,
  });

  final String id;
  final String reportId;
  final String reporterId;
  final FlagReason reason;
  final String? details;
  final FlagReviewStatus reviewStatus;
  final DateTime createdAt;

  ReportFlag copyWith({
    String? id,
    String? reportId,
    String? reporterId,
    FlagReason? reason,
    String? details,
    FlagReviewStatus? reviewStatus,
    DateTime? createdAt,
  }) {
    return ReportFlag(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      reporterId: reporterId ?? this.reporterId,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
