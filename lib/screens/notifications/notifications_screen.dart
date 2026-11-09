import 'package:flutter/material.dart';

import '../../core/services/notification_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/foundit_scope.dart';
import '../../data/models/app_notification.dart';
import '../../widgets/empty_state.dart';
import '../home/report_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isMarkingAllRead = false;

  Future<void> _markAllRead(NotificationRepository repository) async {
    setState(() => _isMarkingAllRead = true);
    try {
      await repository.markAllRead();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notifikasi gagal diperbarui: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  Future<void> _openNotification(
    AppNotification notification,
    NotificationRepository repository,
  ) async {
    try {
      if (!notification.isRead) {
        await repository.markRead(notification.id);
      }
      if (!mounted || notification.reportId == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReportDetailScreen(reportId: notification.reportId!),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notifikasi gagal dibuka: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = FoundItScope.of(context).notificationRepository;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (repository != null)
            ListenableBuilder(
              listenable: repository,
              builder: (context, _) => TextButton(
                onPressed: repository.unreadCount == 0 || _isMarkingAllRead
                    ? null
                    : () => _markAllRead(repository),
                child: _isMarkingAllRead
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tandai dibaca'),
              ),
            ),
        ],
      ),
      body: repository == null
          ? const Center(
              child: Text('Notifikasi tersedia setelah Anda masuk ke akun.'),
            )
          : ListenableBuilder(
              listenable: repository,
              builder: (context, _) {
                final notifications = repository.notifications;
                if (notifications.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: repository.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 110),
                        EmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: 'Belum Ada Notifikasi',
                          subtitle: 'Pembaruan laporan dan laporan yang cocok akan muncul di sini.',
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: repository.refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _NotificationTile(
                        notification: notification,
                        onTap: () =>
                            _openNotification(notification, repository),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = FoundItScope.of(context);
    final notifications = scope.notificationRepository;

    if (notifications == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: scope.authService,
      builder: (context, _) {
        if (!scope.authService.isLoggedIn) return const SizedBox.shrink();
        return ListenableBuilder(
          listenable: notifications,
          builder: (context, _) => IconButton(
            tooltip: 'Notifikasi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            icon: Badge(
              isLabelVisible: notifications.unreadCount > 0,
              label: Text(
                notifications.unreadCount > 99
                    ? '99+'
                    : '${notifications.unreadCount}',
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  IconData get _icon => switch (notification.type) {
    AppNotificationType.matchingReport => Icons.find_in_page_outlined,
    AppNotificationType.adminUpdate => Icons.campaign_outlined,
    AppNotificationType.reportStatus => Icons.assignment_turned_in_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: notification.isRead ? AppColors.surface : AppColors.primarySoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _formatDate(notification.createdAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                const Icon(Icons.circle, size: 9, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour:$minute';
  }
}
