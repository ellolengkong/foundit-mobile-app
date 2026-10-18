import '../../core/constants/report_enums.dart';

/// A lost-or-found report.
///
/// Field names and semantics match DATA_MODEL.md §4.3.
/// [photoPath] stores only the bucket-relative path (e.g. `{ownerId}/{id}.jpg`),
/// never a full URL.
class Report {
  const Report({
    required this.id,
    required this.ownerId,
    required this.reportType,
    required this.itemName,
    required this.category,
    this.description,
    this.photoPath,
    required this.campusArea,
    this.buildingName,
    this.specificLocation,
    required this.eventDate,
    this.status = ReportStatus.active,
    this.moderationStatus = ModerationStatus.visible,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final ReportType reportType;
  final String itemName;

  /// One of the 10 category keys from DATA_MODEL.md §5.2.
  final String category;

  /// Public description. Must NOT contain private verification clues,
  /// ID numbers, or financial details.
  final String? description;

  /// Bucket-relative Storage path, e.g. `{ownerId}/{id}.jpg`.
  final String? photoPath;

  /// Verified faculty/area choice.
  final String campusArea;

  /// Building/facility; null when unknown.
  final String? buildingName;

  /// Free text: floor, room, landmark.
  final String? specificLocation;

  /// Date the item was lost or found (not the report creation date).
  final DateTime eventDate;

  /// Lifecycle status controlled by the owner.
  final ReportStatus status;

  /// Admin-only visibility flag.
  final ModerationStatus moderationStatus;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether this report should appear in the public feed.
  bool get isPubliclyVisible =>
      status == ReportStatus.active &&
      moderationStatus == ModerationStatus.visible;

  /// Creates a copy with the given fields replaced.
  Report copyWith({
    String? id,
    String? ownerId,
    ReportType? reportType,
    String? itemName,
    String? category,
    String? description,
    String? photoPath,
    String? campusArea,
    String? buildingName,
    String? specificLocation,
    DateTime? eventDate,
    ReportStatus? status,
    ModerationStatus? moderationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      reportType: reportType ?? this.reportType,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      campusArea: campusArea ?? this.campusArea,
      buildingName: buildingName ?? this.buildingName,
      specificLocation: specificLocation ?? this.specificLocation,
      eventDate: eventDate ?? this.eventDate,
      status: status ?? this.status,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
