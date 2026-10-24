import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/report_enums.dart';
import '../../data/models/report_flag.dart';

/// Contract for report flag moderation and abuse management in FoundIt.
///
/// Implemented by [SupabaseFlagRepository] for remote Supabase Postgres RPCs
/// and [MockFlagRepository] for offline prototype and test execution.
abstract class FlagRepository extends ChangeNotifier {
  /// Unmodifiable view of all flags in the repository.
  List<ReportFlag> get allFlags;

  /// Flags that are open and pending moderation review.
  List<ReportFlag> get openFlags;

  /// Whether a network or data operation is currently loading.
  bool get isLoading;

  /// Last error message, if any.
  String? get errorMessage;

  /// Submits a new flag for a report.
  FutureOr<bool> submitFlag({
    required String reportId,
    required String reporterId,
    required FlagReason reason,
    String? details,
  });

  /// Updates review status of a flag to dismissed (admin operation).
  FutureOr<void> dismissFlag(String flagId);

  /// Updates review status of a flag to reviewed (admin operation).
  FutureOr<void> reviewFlag(String flagId);

  /// Resolves all open flags associated with a report (admin operation).
  FutureOr<void> resolveFlagsForReport(
    String reportId, {
    FlagReviewStatus status = FlagReviewStatus.reviewed,
  });

  /// Refreshes flag data from the authoritative source.
  Future<void> refresh();
}
