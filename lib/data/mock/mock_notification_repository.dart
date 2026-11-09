import '../../core/services/notification_repository.dart';
import '../models/app_notification.dart';

class MockNotificationRepository extends NotificationRepository {
  MockNotificationRepository({
    List<AppNotification> initialNotifications = const [],
  }) : _notifications = List.of(initialNotifications);

  final List<AppNotification> _notifications;
  String? _userId;

  @override
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  @override
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  @override
  Future<void> bindUser(String? userId) async {
    if (_userId == userId) return;
    _userId = userId;
    _notifications.removeWhere((notification) => notification.userId != userId);
    notifyListeners();
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> markRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index < 0 || _notifications[index].isRead) return;

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

  @override
  Future<void> markAllRead() async {
    final now = DateTime.now();
    for (var index = 0; index < _notifications.length; index++) {
      final current = _notifications[index];
      if (current.isRead) continue;
      _notifications[index] = AppNotification(
        id: current.id,
        userId: current.userId,
        type: current.type,
        title: current.title,
        body: current.body,
        reportId: current.reportId,
        createdAt: current.createdAt,
        readAt: now,
      );
    }
    notifyListeners();
  }
}
