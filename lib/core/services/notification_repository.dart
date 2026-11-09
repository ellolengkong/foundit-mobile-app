import 'package:flutter/foundation.dart';

import '../../data/models/app_notification.dart';

abstract class NotificationRepository extends ChangeNotifier {
  List<AppNotification> get notifications;
  int get unreadCount;

  Future<void> bindUser(String? userId);
  Future<void> refresh();
  Future<void> markRead(String notificationId);
  Future<void> markAllRead();
}
