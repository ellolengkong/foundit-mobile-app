import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/report_enums.dart';
import '../../data/models/report.dart';

/// Contract for report data management and CRUD operations in FoundIt.
///
/// Implemented by [SupabaseReportRepository] for remote Supabase Postgres
/// and [MockReportRepository] for offline prototype and test execution.
abstract class ReportRepository extends ChangeNotifier {
  /// Unmodifiable view of all cached reports.
  List<Report> get allReports;

  /// Returns publicly visible reports matching the filter criteria.
  List<Report> getPublicReports({
    ReportType? type,
    String? category,
    String? campusArea,
    String? buildingName,
    DateTime? startDate,
    DateTime? endDate,
    String? query,
  });

  /// Returns all reports belonging to [ownerId].
  List<Report> getUserReports(String ownerId);

  /// Finds a single report by its ID from memory or cache.
  Report? getReportById(String id);

  /// Checks if [userId] is the verified owner of [reportId].
  bool isUserReportOwner(String reportId, String userId);

  /// Refreshes reports from the source of truth.
  Future<void> refresh();

  /// Creates a new report with optional photo binary.
  Future<Report> createReport(
    Report report, {
    Uint8List? photoBytes,
    String? photoMimeType,
  });

  /// Updates an existing report, with optional photo replacement or removal.
  Future<void> updateReport(
    Report updated, {
    Uint8List? newPhotoBytes,
    String? photoMimeType,
    bool removePhoto = false,
  });

  /// Marks a report as resolved.
  Future<void> resolveReport(String id);

  /// Reopens a resolved report back to active.
  Future<void> reopenReport(String id);

  /// Deletes a report and associated photo.
  Future<void> deleteReport(String id);

  /// Changes the moderation status of a report (admin operation).
  FutureOr<void> setModerationStatus(String id, ModerationStatus status);
}
