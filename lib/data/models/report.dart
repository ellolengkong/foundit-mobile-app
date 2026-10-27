import '../../core/constants/report_enums.dart';
import '../../core/services/supabase_service.dart';

/// A lost-or-found report.
///
/// Field names and semantics match DATA_MODEL.md §4.3.
/// [photoPath] stores only the bucket-relative path (e.g. `{report_id}/photo`),
/// never a full URL.
class Report {
  const Report({
    required this.id,
    this.ownerId = '',
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

  /// Owner UUID (empty string when loaded from public_reports view for privacy).
  final String ownerId;
  final ReportType reportType;
  final String itemName;

  /// One of the 10 category keys from DATA_MODEL.md §5.2.
  final String category;

  /// Public description. Must NOT contain private verification clues,
  /// ID numbers, or financial details.
  final String? description;

  /// Bucket-relative Storage path, e.g. `{report_id}/photo`.
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

  /// Returns the full public URL for [photoPath] if Supabase is initialized.
  String? get publicPhotoUrl => resolvePhotoUrl(photoPath);

  /// Resolves bucket-relative [path] to a public URL.
  static String? resolvePhotoUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (SupabaseService.isInitialized) {
      return SupabaseService.client.storage
          .from('report-photos')
          .getPublicUrl(trimmed);
    }
    return null;
  }

  /// Deserializes a report from Supabase JSON / PostgREST map.
  factory Report.fromMap(Map<String, dynamic> map) {
    final typeKey = map['report_type'] as String? ?? 'lost';
    final reportType = typeKey == 'found' ? ReportType.found : ReportType.lost;

    final statusKey = map['status'] as String? ?? 'active';
    final status = statusKey == 'resolved'
        ? ReportStatus.resolved
        : ReportStatus.active;

    final modKey = map['moderation_status'] as String? ?? 'visible';
    final moderationStatus = modKey == 'hidden'
        ? ModerationStatus.hidden
        : ModerationStatus.visible;

    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Report(
      id: map['id'] as String? ?? '',
      ownerId: map['owner_id'] as String? ?? '',
      reportType: reportType,
      itemName: map['item_name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String?,
      photoPath: map['photo_path'] as String?,
      campusArea: map['campus_area'] as String? ?? '',
      buildingName: map['building_name'] as String?,
      specificLocation: map['specific_location'] as String?,
      eventDate: parseDate(map['event_date']),
      status: status,
      moderationStatus: moderationStatus,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  /// Map suitable for INSERT according to least-privilege column grants.
  /// Note: id, owner_id, status, moderation_status, created_at, updated_at
  /// are filled by PostgreSQL database defaults.
  Map<String, dynamic> toInsertMap() {
    return {
      'report_type': reportType.key,
      'item_name': itemName,
      'category': category,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (photoPath != null && photoPath!.trim().isNotEmpty)
        'photo_path': photoPath!.trim(),
      'campus_area': campusArea,
      if (buildingName != null && buildingName!.trim().isNotEmpty)
        'building_name': buildingName!.trim(),
      if (specificLocation != null && specificLocation!.trim().isNotEmpty)
        'specific_location': specificLocation!.trim(),
      'event_date':
          "${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}",
    };
  }

  /// Map suitable for UPDATE according to least-privilege column grants.
  Map<String, dynamic> toUpdateMap() {
    return {
      'report_type': reportType.key,
      'item_name': itemName,
      'category': category,
      'description': description?.trim(),
      'photo_path': photoPath?.trim(),
      'campus_area': campusArea,
      'building_name': buildingName?.trim(),
      'specific_location': specificLocation?.trim(),
      'event_date':
          "${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}",
      'status': status.key,
    };
  }

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
