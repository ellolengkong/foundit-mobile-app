import 'package:flutter/foundation.dart';

import '../../core/constants/report_enums.dart';
import '../models/report_flag.dart';

/// In-memory repository acting as the mock source of truth for report flags.
class MockFlagRepository extends ChangeNotifier {
  MockFlagRepository()
    : _flags = [
        ReportFlag(
          id: 'flag-001',
          reportId: 'mock-001',
          reporterId: 'user-002',
          reason: FlagReason.spam,
          details: 'Laporan tampak berulang dan tidak jelas.',
          reviewStatus: FlagReviewStatus.open,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        ReportFlag(
          id: 'flag-002',
          reportId: 'mock-003',
          reporterId: 'user-004',
          reason: FlagReason.inappropriate,
          details: 'Informasi tempat tidak sesuai lokasi kampus.',
          reviewStatus: FlagReviewStatus.open,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

  final List<ReportFlag> _flags;

  /// Unmodifiable view of all flags in repository.
  List<ReportFlag> get allFlags => List.unmodifiable(_flags);

  /// Only flags that are open and pending review.
  List<ReportFlag> get openFlags =>
      _flags.where((f) => f.reviewStatus == FlagReviewStatus.open).toList();

  /// Submits a new flag for a report.
  ///
  /// Prevents duplicate flagging of the same report by the same user.
  bool submitFlag({
    required String reportId,
    required String reporterId,
    required FlagReason reason,
    String? details,
  }) {
    final alreadyFlagged = _flags.any(
      (f) => f.reportId == reportId && f.reporterId == reporterId,
    );
    if (alreadyFlagged) {
      return false;
    }

    final newFlag = ReportFlag(
      id: 'flag-${DateTime.now().millisecondsSinceEpoch}',
      reportId: reportId,
      reporterId: reporterId,
      reason: reason,
      details: details,
      reviewStatus: FlagReviewStatus.open,
      createdAt: DateTime.now(),
    );

    _flags.insert(0, newFlag);
    notifyListeners();
    return true;
  }

  /// Updates review status of a flag.
  void updateReviewStatus(String flagId, FlagReviewStatus status) {
    final idx = _flags.indexWhere((f) => f.id == flagId);
    if (idx != -1) {
      _flags[idx] = _flags[idx].copyWith(reviewStatus: status);
      notifyListeners();
    }
  }

  void dismissFlag(String flagId) =>
      updateReviewStatus(flagId, FlagReviewStatus.dismissed);

  void reviewFlag(String flagId) =>
      updateReviewStatus(flagId, FlagReviewStatus.reviewed);

  /// Resolves all open flags associated with a report (e.g. when hidden by admin).
  void resolveFlagsForReport(
    String reportId, {
    FlagReviewStatus status = FlagReviewStatus.reviewed,
  }) {
    bool updated = false;
    for (int i = 0; i < _flags.length; i++) {
      if (_flags[i].reportId == reportId &&
          _flags[i].reviewStatus == FlagReviewStatus.open) {
        _flags[i] = _flags[i].copyWith(reviewStatus: status);
        updated = true;
      }
    }
    if (updated) {
      notifyListeners();
    }
  }
}
