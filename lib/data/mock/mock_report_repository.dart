import 'dart:typed_data';

import '../../core/constants/report_enums.dart';
import '../../core/services/report_repository.dart';
import '../models/report.dart';
import 'mock_reports.dart';

/// In-memory repository acting as the single source of truth for reports in M1.
///
/// Pre-populated with [kMockReports]. Mutating operations notify listeners
/// so screens rebuild automatically.
class MockReportRepository extends ReportRepository {
  MockReportRepository() : _reports = List<Report>.from(kMockReports);

  final List<Report> _reports;

  /// All reports in the repository (unmodifiable view).
  @override
  List<Report> get allReports => List.unmodifiable(_reports);

  /// Returns publicly visible reports filtered by criteria.
  ///
  /// Public feed rule: only active + visible reports appear.
  @override
  List<Report> getPublicReports({
    ReportType? type,
    String? category,
    String? campusArea,
    String? buildingName,
    DateTime? startDate,
    DateTime? endDate,
    String? query,
  }) {
    return _reports.where((r) {
      if (!r.isPubliclyVisible) return false;

      if (type != null && r.reportType != type) return false;
      if (category != null && category.isNotEmpty && r.category != category) {
        return false;
      }
      if (campusArea != null &&
          campusArea.isNotEmpty &&
          r.campusArea != campusArea) {
        return false;
      }
      if (buildingName != null &&
          buildingName.isNotEmpty &&
          buildingName != 'Tidak tahu' &&
          r.buildingName != buildingName) {
        return false;
      }

      if (startDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        if (r.eventDate.isBefore(start)) return false;
      }
      if (endDate != null) {
        final end = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
          999,
        );
        if (r.eventDate.isAfter(end)) return false;
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final nameMatch = r.itemName.toLowerCase().contains(q);
        final descMatch = r.description?.toLowerCase().contains(q) ?? false;
        final locMatch =
            r.campusArea.toLowerCase().contains(q) ||
            (r.buildingName?.toLowerCase().contains(q) ?? false);
        if (!nameMatch && !descMatch && !locMatch) return false;
      }

      return true;
    }).toList();
  }

  /// Returns all reports belonging to [ownerId], including resolved and hidden.
  @override
  List<Report> getUserReports(String ownerId) {
    return _reports.where((r) => r.ownerId == ownerId).toList();
  }

  /// Finds a single report by its ID.
  @override
  Report? getReportById(String id) {
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  bool isUserReportOwner(String reportId, String userId) {
    return getUserReports(userId).any((r) => r.id == reportId);
  }

  @override
  Future<void> refresh() {
    return Future.value();
  }

  /// Adds a new report to the repository (inserted at top).
  @override
  Future<Report> createReport(
    Report report, {
    Uint8List? photoBytes,
    String? photoMimeType,
  }) {
    _reports.insert(0, report);
    notifyListeners();
    return Future.value(report);
  }

  /// Updates an existing report.
  @override
  Future<void> updateReport(
    Report updated, {
    Uint8List? newPhotoBytes,
    String? photoMimeType,
    bool removePhoto = false,
  }) {
    final idx = _reports.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _reports[idx] = updated.copyWith(
        photoPath: removePhoto ? null : updated.photoPath,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
    return Future.value();
  }

  /// Marks a report as resolved.
  @override
  Future<void> resolveReport(String id) {
    final idx = _reports.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reports[idx] = _reports[idx].copyWith(
        status: ReportStatus.resolved,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
    return Future.value();
  }

  /// Reopens a resolved report back to active.
  @override
  Future<void> reopenReport(String id) {
    final idx = _reports.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reports[idx] = _reports[idx].copyWith(
        status: ReportStatus.active,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
    return Future.value();
  }

  /// Deletes a report from the repository.
  @override
  Future<void> deleteReport(String id) {
    _reports.removeWhere((r) => r.id == id);
    notifyListeners();
    return Future.value();
  }

  /// Changes the moderation status of a report (admin operation).
  @override
  void setModerationStatus(String id, ModerationStatus status) {
    final idx = _reports.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reports[idx] = _reports[idx].copyWith(
        moderationStatus: status,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }
}
