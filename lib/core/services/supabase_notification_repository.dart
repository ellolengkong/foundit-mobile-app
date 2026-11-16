import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/app_notification.dart';
import 'notification_repository.dart';
import 'supabase_service.dart';

class SupabaseNotificationRepository extends NotificationRepository {
  SupabaseNotificationRepository({SupabaseClient? client})
    : _customClient = client;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? SupabaseService.client;

  List<AppNotification> _notifications = const [];
  RealtimeChannel? _channel;
  String? _userId;

  @override
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  @override
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  @override
  Future<void> bindUser(String? userId) async {
    if (_userId == userId) return;
    _userId = userId;
    final previousChannel = _channel;
    _channel = null;
    if (previousChannel != null) {
      await _client.removeChannel(previousChannel);
    }

    _notifications = const [];
    notifyListeners();
    if (userId == null) return;

    await refresh();
    if (_userId != userId) return;

    final channel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => unawaited(_refreshAndReportErrors()),
        );
    _channel = channel;
    channel.subscribe((status, error) {
      if (error != null) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            library: 'Supabase notifications',
            context: ErrorDescription('while subscribing to notifications'),
          ),
        );
      }
    });
  }

  Future<void> _refreshAndReportErrors() async {
    try {
      await refresh();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Supabase notifications',
          context: ErrorDescription('while refreshing notifications'),
        ),
      );
    }
  }

  @override
  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;

    final rows = await _client
        .from('notifications')
        .select(
          'id, user_id, notification_type, title, body, report_id, created_at, read_at',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);

    if (_userId != userId) return;
    _notifications = rows
        .map((row) => AppNotification.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
    notifyListeners();
  }

  @override
  Future<void> markRead(String notificationId) async {
    final userId = _userId;
    if (userId == null) return;
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .eq('user_id', userId);

    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index >= 0 && !_notifications[index].isRead) {
      final current = _notifications[index];
      _notifications[index] = AppNotification(
        id: current.id,
        userId: current.userId,
        type: current.type,
        title: current.title,
        body: current.body,
        reportId: current.reportId,
        createdAt: current.createdAt,
        readAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  @override
  Future<void> markAllRead() async {
    final userId = _userId;
    if (userId == null || unreadCount == 0) return;

    final now = DateTime.now();
    await _client
        .from('notifications')
        .update({'read_at': now.toUtc().toIso8601String()})
        .eq('user_id', userId)
        .filter('read_at', 'is', null);

    _notifications = _notifications
        .map(
          (item) => item.isRead
              ? item
              : AppNotification(
                  id: item.id,
                  userId: item.userId,
                  type: item.type,
                  title: item.title,
                  body: item.body,
                  reportId: item.reportId,
                  createdAt: item.createdAt,
                  readAt: now,
                ),
        )
        .toList(growable: false);
    notifyListeners();
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) unawaited(_client.removeChannel(channel));
    super.dispose();
  }
}
