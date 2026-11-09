import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/data/mock/foundit_scope.dart';
import 'package:foundit/data/mock/mock_auth_service.dart';
import 'package:foundit/data/mock/mock_flag_repository.dart';
import 'package:foundit/data/mock/mock_notification_repository.dart';
import 'package:foundit/data/mock/mock_report_repository.dart';
import 'package:foundit/data/models/app_notification.dart';
import 'package:foundit/screens/notifications/notifications_screen.dart';

void main() {
  testWidgets('bell opens notifications and marks an item read', (
    tester,
  ) async {
    final authService = MockAuthService();
    await authService.login(
      email: 'user-001@example.com',
      password: 'password',
      userId: 'user-001',
    );
    final notificationRepository = MockNotificationRepository(
      initialNotifications: [
        AppNotification(
          id: 'notification-001',
          userId: 'user-001',
          type: AppNotificationType.matchingReport,
          title: 'Laporan yang mungkin cocok',
          body: 'Ada laporan baru yang mungkin cocok.',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    addTearDown(notificationRepository.dispose);
    addTearDown(authService.dispose);

    await tester.pumpWidget(
      FoundItScope(
        repository: MockReportRepository(),
        authService: authService,
        flagRepository: MockFlagRepository(),
        notificationRepository: notificationRepository,
        child: const MaterialApp(
          home: Scaffold(body: NotificationBellButton()),
        ),
      ),
    );

    expect(notificationRepository.unreadCount, 1);
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Laporan yang mungkin cocok'), findsOneWidget);
    await tester.tap(find.text('Laporan yang mungkin cocok'));
    await tester.pumpAndSettle();

    expect(notificationRepository.unreadCount, 0);
    expect(notificationRepository.notifications.single.isRead, isTrue);
  });

  test('unknown notification type is rejected', () {
    expect(() => AppNotificationType.fromKey('unknown'), throwsArgumentError);
  });

  test('mock repository clears notifications on logout', () async {
    final repository = MockNotificationRepository(
      initialNotifications: [
        AppNotification(
          id: 'notification-001',
          userId: 'user-001',
          type: AppNotificationType.reportStatus,
          title: 'Status laporan berubah',
          body: 'Status laporan Anda berubah.',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    addTearDown(repository.dispose);
    await repository.bindUser('user-001');
    expect(repository.unreadCount, 1);

    await repository.bindUser(null);

    expect(repository.notifications, isEmpty);
    expect(repository.unreadCount, 0);
  });
}
