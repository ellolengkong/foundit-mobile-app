enum AppNotificationType {
  reportStatus('report_status'),
  matchingReport('matching_report'),
  adminUpdate('admin_update');

  const AppNotificationType(this.key);

  final String key;

  static AppNotificationType fromKey(String? key) => switch (key) {
    'report_status' => AppNotificationType.reportStatus,
    'matching_report' => AppNotificationType.matchingReport,
    'admin_update' => AppNotificationType.adminUpdate,
    _ => throw ArgumentError.value(key, 'key', 'Unknown notification type'),
  };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.reportId,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? reportId;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: AppNotificationType.fromKey(map['notification_type'] as String?),
      title: map['title'] as String,
      body: map['body'] as String,
      reportId: map['report_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      readAt: map['read_at'] == null
          ? null
          : DateTime.parse(map['read_at'] as String),
    );
  }
}
