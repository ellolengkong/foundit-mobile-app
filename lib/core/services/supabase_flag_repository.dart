import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/report_enums.dart';
import '../../data/models/report_flag.dart';
import 'flag_repository.dart';
import 'supabase_service.dart';

/// Production report flag repository connecting to Supabase PostgreSQL.
///
/// Implements moderation operations using:
/// - Table `public.report_flags` for storing and reading flags.
/// - Database RPC `public.admin_review_flag(p_flag_id, p_review_status)` for
///   moderating flag review status as verified admin.
class SupabaseFlagRepository extends FlagRepository {
  SupabaseFlagRepository({SupabaseClient? client})
      : _customClient = client {
    refresh();
  }

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? SupabaseService.client;

  List<ReportFlag> _flags = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  List<ReportFlag> get allFlags => List.unmodifiable(_flags);

  @override
  List<ReportFlag> get openFlags =>
      _flags.where((f) => f.reviewStatus == FlagReviewStatus.open).toList();

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client
          .from('report_flags')
          .select()
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((item) => ReportFlag.fromMap(item as Map<String, dynamic>))
          .toList();

      _flags = list;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Failed to fetch report flags: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<bool> submitFlag({
    required String reportId,
    required String reporterId,
    required FlagReason reason,
    String? details,
  }) async {
    // Check locally first
    final alreadyFlagged = _flags.any(
      (f) => f.reportId == reportId && f.reporterId == reporterId,
    );
    if (alreadyFlagged) {
      return false;
    }

    try {
      final flagToInsert = ReportFlag(
        id: '', // Excluded by toInsertMap()
        reportId: reportId,
        reporterId: reporterId,
        reason: reason,
        details: details,
        createdAt: DateTime.now(),
      );

      final inserted = await _client
          .from('report_flags')
          .insert(flagToInsert.toInsertMap())
          .select()
          .single();

      final newFlag = ReportFlag.fromMap(inserted);
      _flags.insert(0, newFlag);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SupabaseFlagRepository.submitFlag error: $e');
      return false;
    }
  }

  @override
  Future<void> dismissFlag(String flagId) async {
    try {
      await _client.rpc('admin_review_flag', params: {
        'p_flag_id': flagId,
        'p_review_status': 'dismissed',
      });

      final idx = _flags.indexWhere((f) => f.id == flagId);
      if (idx != -1) {
        _flags[idx] = _flags[idx].copyWith(
          reviewStatus: FlagReviewStatus.dismissed,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('SupabaseFlagRepository.dismissFlag error: $e');
      rethrow;
    }
  }

  @override
  Future<void> reviewFlag(String flagId) async {
    try {
      await _client.rpc('admin_review_flag', params: {
        'p_flag_id': flagId,
        'p_review_status': 'reviewed',
      });

      final idx = _flags.indexWhere((f) => f.id == flagId);
      if (idx != -1) {
        _flags[idx] = _flags[idx].copyWith(
          reviewStatus: FlagReviewStatus.reviewed,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('SupabaseFlagRepository.reviewFlag error: $e');
      rethrow;
    }
  }

  @override
  Future<void> resolveFlagsForReport(
    String reportId, {
    FlagReviewStatus status = FlagReviewStatus.reviewed,
  }) async {
    final targets = _flags
        .where(
          (f) =>
              f.reportId == reportId &&
              f.reviewStatus == FlagReviewStatus.open,
        )
        .toList();

    for (final flag in targets) {
      try {
        await _client.rpc('admin_review_flag', params: {
          'p_flag_id': flag.id,
          'p_review_status': status.key,
        });

        final idx = _flags.indexWhere((f) => f.id == flag.id);
        if (idx != -1) {
          _flags[idx] = _flags[idx].copyWith(reviewStatus: status);
        }
      } catch (e) {
        debugPrint('SupabaseFlagRepository.resolveFlagsForReport error: $e');
      }
    }

    if (targets.isNotEmpty) {
      notifyListeners();
    }
  }
}
