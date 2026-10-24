import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/report_enums.dart';
import '../../data/models/report.dart';
import 'report_repository.dart';
import 'supabase_service.dart';

/// Production report repository powered by Supabase PostgreSQL and Storage.
///
/// Implements least-privilege CRUD:
/// - Public feed/filtering reads from the `public_reports` view.
/// - Authenticated users create reports with server-assigned `owner_id = auth.uid()`.
/// - Photos are stored in `report-photos` bucket at `{report_id}/photo`.
/// - Owner can edit content, resolve, and delete their own reports.
class SupabaseReportRepository extends ReportRepository {
  SupabaseReportRepository({SupabaseClient? client})
      : _customClient = client {
    refresh();
  }

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? SupabaseService.client;

  List<Report> _publicReports = [];
  List<Report> _userReports = [];
  List<Report> _adminReports = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  List<Report> get allReports => _adminReports.isNotEmpty
      ? List.unmodifiable(_adminReports)
      : List.unmodifiable([..._publicReports]);

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
    return _publicReports.where((r) {
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

  @override
  List<Report> getUserReports(String ownerId) {
    // If cache is empty or user ID matches current authenticated user,
    // trigger background fetch if needed
    if (_userReports.isEmpty && _client.auth.currentUser?.id == ownerId) {
      fetchUserReports(ownerId);
    }
    return _userReports.where((r) => r.ownerId == ownerId).toList();
  }

  @override
  Report? getReportById(String id) {
    try {
      return _userReports.firstWhere(
        (r) => r.id == id,
        orElse: () => _publicReports.firstWhere((r) => r.id == id),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool isUserReportOwner(String reportId, String userId) {
    return _userReports.any((r) => r.id == reportId) ||
        _publicReports.any((r) => r.id == reportId && r.ownerId == userId);
  }

  @override
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await fetchPublicReports();
      final currentUid = _client.auth.currentUser?.id;
      if (currentUid != null) {
        await fetchUserReports(currentUid);
        if (_adminReports.isNotEmpty) {
          await fetchAdminReports();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches all reports across all users from the base `reports` table.
  /// Permitted for admins via RLS policy `reports_select_own` (which checks `public.is_admin()`).
  Future<void> fetchAdminReports() async {
    try {
      final response = await _client
          .from('reports')
          .select()
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((item) => Report.fromMap(item as Map<String, dynamic>))
          .toList();

      _adminReports = list;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch admin reports: $e');
    }
  }

  /// Fetches active & visible public reports from the `public_reports` view.
  Future<void> fetchPublicReports() async {
    try {
      final response = await _client
          .from('public_reports')
          .select()
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((item) => Report.fromMap(item as Map<String, dynamic>))
          .toList();

      _publicReports = list;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch public_reports: $e');
      rethrow;
    }
  }

  /// Fetches own reports from the `reports` table.
  Future<void> fetchUserReports(String ownerId) async {
    try {
      final response = await _client
          .from('reports')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((item) => Report.fromMap(item as Map<String, dynamic>))
          .toList();

      _userReports = list;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch user reports: $e');
    }
  }

  @override
  Future<Report> createReport(
    Report report, {
    Uint8List? photoBytes,
    String? photoMimeType,
  }) async {
    // 1. Insert to public.reports
    // PostgreSQL defaults fill: id, owner_id, status ('active'),
    // moderation_status ('visible'), created_at, updated_at
    final insertedData = await _client
        .from('reports')
        .insert(report.toInsertMap())
        .select()
        .single();

    var createdReport = Report.fromMap(insertedData);

    // 2. Upload optional photo to Supabase Storage
    if (photoBytes != null && photoBytes.isNotEmpty) {
      if (photoBytes.length > 1048576) {
        throw StateError('Ukuran foto melebihi batas maksimum 1 MB.');
      }

      final objectPath = '${createdReport.id}/photo';
      final mime = photoMimeType ?? 'image/jpeg';

      try {
        await _client.storage.from('report-photos').uploadBinary(
          objectPath,
          photoBytes,
          fileOptions: FileOptions(
            contentType: mime,
            upsert: true,
          ),
        );

        // 3. Update photo_path in public.reports
        await _client.from('reports').update({
          'photo_path': objectPath,
        }).eq('id', createdReport.id);

        createdReport = createdReport.copyWith(photoPath: objectPath);
      } catch (e) {
        debugPrint('Photo upload failed: $e');
        // Report exists without photo as per specification
      }
    }

    _userReports.insert(0, createdReport);
    if (createdReport.isPubliclyVisible) {
      _publicReports.insert(0, createdReport);
    }
    notifyListeners();
    return createdReport;
  }

  @override
  Future<void> updateReport(
    Report updated, {
    Uint8List? newPhotoBytes,
    String? photoMimeType,
    bool removePhoto = false,
  }) async {
    String? currentPhotoPath = updated.photoPath;

    // 1. Handle photo removal
    if (removePhoto && currentPhotoPath != null) {
      try {
        await _client.storage
            .from('report-photos')
            .remove([currentPhotoPath]);
      } catch (_) {}
      currentPhotoPath = null;
    }
    // 2. Handle new photo upload
    else if (newPhotoBytes != null && newPhotoBytes.isNotEmpty) {
      if (newPhotoBytes.length > 1048576) {
        throw StateError('Ukuran foto melebihi batas maksimum 1 MB.');
      }

      final objectPath = '${updated.id}/photo';
      final mime = photoMimeType ?? 'image/jpeg';

      await _client.storage.from('report-photos').uploadBinary(
        objectPath,
        newPhotoBytes,
        fileOptions: FileOptions(
          contentType: mime,
          upsert: true,
        ),
      );
      currentPhotoPath = objectPath;
    }

    // 3. Update report content in public.reports
    final updatePayload = {
      ...updated.toUpdateMap(),
      'photo_path': currentPhotoPath,
    };

    await _client
        .from('reports')
        .update(updatePayload)
        .eq('id', updated.id);

    final finalReport = updated.copyWith(
      photoPath: currentPhotoPath,
      updatedAt: DateTime.now(),
    );

    // Update in-memory caches
    final userIdx = _userReports.indexWhere((r) => r.id == updated.id);
    if (userIdx != -1) {
      _userReports[userIdx] = finalReport;
    }

    final pubIdx = _publicReports.indexWhere((r) => r.id == updated.id);
    if (pubIdx != -1) {
      if (finalReport.isPubliclyVisible) {
        _publicReports[pubIdx] = finalReport;
      } else {
        _publicReports.removeAt(pubIdx);
      }
    } else if (finalReport.isPubliclyVisible) {
      _publicReports.insert(0, finalReport);
    }

    notifyListeners();
  }

  @override
  Future<void> resolveReport(String id) async {
    await _client
        .from('reports')
        .update({'status': 'resolved'}).eq('id', id);

    final userIdx = _userReports.indexWhere((r) => r.id == id);
    if (userIdx != -1) {
      _userReports[userIdx] = _userReports[userIdx].copyWith(
        status: ReportStatus.resolved,
        updatedAt: DateTime.now(),
      );
    }

    _publicReports.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  @override
  Future<void> reopenReport(String id) async {
    await _client
        .from('reports')
        .update({'status': 'active'}).eq('id', id);

    final userIdx = _userReports.indexWhere((r) => r.id == id);
    if (userIdx != -1) {
      final updated = _userReports[userIdx].copyWith(
        status: ReportStatus.active,
        updatedAt: DateTime.now(),
      );
      _userReports[userIdx] = updated;
      if (updated.isPubliclyVisible) {
        _publicReports.insert(0, updated);
      }
    }
    notifyListeners();
  }

  @override
  Future<void> deleteReport(String id) async {
    final report = getReportById(id);
    if (report?.photoPath != null && report!.photoPath!.isNotEmpty) {
      try {
        await _client.storage
            .from('report-photos')
            .remove([report.photoPath!]);
      } catch (_) {}
    }

    await _client.from('reports').delete().eq('id', id);

    _userReports.removeWhere((r) => r.id == id);
    _publicReports.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  @override
  Future<void> setModerationStatus(String id, ModerationStatus status) async {
    try {
      // 1. Invoke RPC admin_set_report_moderation (admin only)
      await _client.rpc('admin_set_report_moderation', params: {
        'p_report_id': id,
        'p_moderation_status': status.key, // 'visible' or 'hidden'
      });

      // 2. Update local _adminReports cache
      final adminIdx = _adminReports.indexWhere((r) => r.id == id);
      if (adminIdx != -1) {
        _adminReports[adminIdx] = _adminReports[adminIdx].copyWith(
          moderationStatus: status,
          updatedAt: DateTime.now(),
        );
      }

      // 3. Update local _publicReports cache
      if (status == ModerationStatus.hidden) {
        _publicReports.removeWhere((r) => r.id == id);
      } else {
        final pubIdx = _publicReports.indexWhere((r) => r.id == id);
        if (pubIdx != -1) {
          _publicReports[pubIdx] = _publicReports[pubIdx].copyWith(
            moderationStatus: status,
            updatedAt: DateTime.now(),
          );
        } else {
          final rep = getReportById(id);
          if (rep != null && rep.status == ReportStatus.active) {
            _publicReports.insert(0, rep.copyWith(moderationStatus: status));
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('SupabaseReportRepository.setModerationStatus error: $e');
      rethrow;
    }
  }
}
