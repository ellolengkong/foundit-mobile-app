import 'package:flutter/material.dart';

import '../../core/constants/report_enums.dart';
import '../../core/services/supabase_report_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/foundit_scope.dart';
import '../../data/mock/mock_flag_repository.dart';
import '../../data/models/report.dart';
import '../../data/models/report_flag.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_status_badge.dart';
import '../../widgets/status_chip.dart';
import '../home/report_detail_screen.dart';

/// Admin moderation dashboard.
///
/// Guarded by [AuthService.canAccessAdmin]. Connects to Supabase RPCs:
/// - [admin_set_report_moderation] for hiding/showing reports.
/// - [admin_review_flag] for reviewing or dismissing abuse flags.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  void _showActionSnackBar(
    ScaffoldMessengerState messenger,
    SnackBar snackBar,
  ) {
    if (!messenger.mounted) return;
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(snackBar);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final scope = FoundItScope.of(context);
    if (!scope.authService.canAccessAdmin) return;

    await scope.flagRepository.refresh();
    if (scope.repository is SupabaseReportRepository) {
      await (scope.repository as SupabaseReportRepository).fetchAdminReports();
    }
  }

  Future<void> _handleRefresh() async {
    final scope = FoundItScope.of(context);
    if (!scope.authService.canAccessAdmin) return;

    await scope.flagRepository.refresh();
    if (scope.repository is SupabaseReportRepository) {
      await (scope.repository as SupabaseReportRepository).fetchAdminReports();
    } else {
      await scope.repository.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = FoundItScope.of(context);

    // ── Security Check ────────────────────────────────────────────────────────
    if (!scope.authService.canAccessAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses Ditolak')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Anda tidak memiliki izin untuk mengakses Dashboard Admin.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isMock = scope.flagRepository is MockFlagRepository;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isMock ? 'Dashboard Admin (Mock)' : 'Dashboard Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Semua Laporan'),
              Tab(text: 'Dilaporkan'),
              Tab(text: 'Disembunyikan'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([
            scope.repository,
            scope.flagRepository,
          ]),
          builder: (context, _) {
            final allReports = scope.repository.allReports;
            final hiddenReports = allReports
                .where((r) => r.moderationStatus == ModerationStatus.hidden)
                .toList();
            final flags = scope.flagRepository.allFlags;

            return Column(
              children: [
                if (scope.flagRepository.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                if (scope.flagRepository.errorMessage != null)
                  Container(
                    width: double.infinity,
                    color: AppColors.error.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Peringatan: ${scope.flagRepository.errorMessage}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: _buildReportList(
                          context,
                          scope,
                          allReports,
                          'Belum ada laporan',
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: _buildFlaggedList(context, scope, flags),
                      ),
                      RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: _buildReportList(
                          context,
                          scope,
                          hiddenReports,
                          'Tidak ada laporan yang disembunyikan',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlaggedList(
    BuildContext context,
    FoundItScope scope,
    List<ReportFlag> flags,
  ) {
    if (flags.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          EmptyState(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Tidak ada laporan yang dilaporkan',
            subtitle: 'Tidak ada laporan yang ditandai bermasalah saat ini.',
          ),
        ],
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: flags.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final flag = flags[index];
        final report = scope.repository.getReportById(flag.reportId);
        final isOpen = flag.reviewStatus == FlagReviewStatus.open;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lostSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Alasan: ${flag.reason.label}',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.lost,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? AppColors.primarySoft
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        flag.reviewStatus.label,
                        style: textTheme.labelSmall?.copyWith(
                          color: isOpen
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  report != null
                      ? report.itemName
                      : 'Laporan [ID: ${flag.reportId}]',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (report != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${report.campusArea} · Dilaporkan oleh: ${flag.reporterId}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (flag.details != null && flag.details!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Catatan: "${flag.details}"',
                    style: textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const Divider(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (report != null)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReportDetailScreen(reportId: report.id),
                            ),
                          );
                        },
                        child: const Text('Lihat Laporan'),
                      ),
                    if (isOpen) ...[
                      OutlinedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await scope.flagRepository.dismissFlag(flag.id);
                            _showActionSnackBar(
                              messenger,
                              const SnackBar(
                                content: Text(
                                  'Laporan penyalahgunaan diabaikan.',
                                ),
                              ),
                            );
                          } catch (e) {
                            _showActionSnackBar(
                              messenger,
                              SnackBar(
                                content: Text('Gagal mengabaikan laporan: $e'),
                              ),
                            );
                          }
                        },
                        child: const Text('Abaikan'),
                      ),
                      FilledButton.tonal(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            if (report != null) {
                              await scope.repository.setModerationStatus(
                                report.id,
                                ModerationStatus.hidden,
                              );
                              await scope.flagRepository.resolveFlagsForReport(
                                report.id,
                                status: FlagReviewStatus.reviewed,
                              );
                            } else {
                              await scope.flagRepository.reviewFlag(flag.id);
                            }
                            _showActionSnackBar(
                              messenger,
                              const SnackBar(
                                content: Text(
                                  'Laporan disembunyikan dan flag ditandai selesai.',
                                ),
                              ),
                            );
                          } catch (e) {
                            _showActionSnackBar(
                              messenger,
                              SnackBar(
                                content: Text('Gagal memoderasi laporan: $e'),
                              ),
                            );
                          }
                        },
                        child: const Text('Sembunyikan & Selesai'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportList(
    BuildContext context,
    FoundItScope scope,
    List<Report> reports,
    String emptyMessage,
  ) {
    if (reports.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          EmptyState(
            icon: Icons.assignment_turned_in_outlined,
            title: emptyMessage,
          ),
        ],
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = reports[index];
        final isHidden = r.moderationStatus == ModerationStatus.hidden;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(reportType: r.reportType),
                    const SizedBox(width: 8),
                    ReportStatusBadge(status: r.status),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isHidden
                            ? AppColors.lostSoft
                            : AppColors.foundSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.moderationStatus.label,
                        style: textTheme.labelSmall?.copyWith(
                          color: isHidden ? AppColors.lost : AppColors.found,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.itemName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${r.campusArea} · ID: ${r.id}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Divider(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportDetailScreen(reportId: r.id),
                          ),
                        );
                      },
                      child: const Text('Lihat Detail'),
                    ),
                    if (isHidden)
                      FilledButton.tonal(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await scope.repository.setModerationStatus(
                              r.id,
                              ModerationStatus.visible,
                            );
                            _showActionSnackBar(
                              messenger,
                              const SnackBar(
                                content: Text(
                                  'Laporan kini ditampilkan ke publik.',
                                ),
                              ),
                            );
                          } catch (e) {
                            _showActionSnackBar(
                              messenger,
                              SnackBar(
                                content: Text('Gagal menampilkan laporan: $e'),
                              ),
                            );
                          }
                        },
                        child: const Text('Tampilkan'),
                      )
                    else
                      OutlinedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await scope.repository.setModerationStatus(
                              r.id,
                              ModerationStatus.hidden,
                            );
                            await scope.flagRepository.resolveFlagsForReport(
                              r.id,
                              status: FlagReviewStatus.reviewed,
                            );
                            _showActionSnackBar(
                              messenger,
                              const SnackBar(
                                content: Text(
                                  'Laporan disembunyikan dan flag terkait ditandai selesai.',
                                ),
                              ),
                            );
                          } catch (e) {
                            _showActionSnackBar(
                              messenger,
                              SnackBar(
                                content: Text(
                                  'Gagal menyembunyikan laporan: $e',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Sembunyikan'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
