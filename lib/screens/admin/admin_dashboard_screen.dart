import 'package:flutter/material.dart';

import '../../core/constants/report_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/foundit_scope.dart';
import '../../data/models/report.dart';
import '../../data/models/report_flag.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_status_badge.dart';
import '../../widgets/status_chip.dart';
import '../home/report_detail_screen.dart';

/// Admin moderation dashboard (Mock M1).
///
/// Only accessible when mock admin mode is active.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = FoundItScope.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Admin (Mock)'),
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

            return TabBarView(
              children: [
                _buildReportList(
                  context,
                  scope,
                  allReports,
                  'Belum ada laporan',
                ),
                _buildFlaggedList(context, scope, flags),
                _buildReportList(
                  context,
                  scope,
                  hiddenReports,
                  'Tidak ada laporan yang disembunyikan',
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
      return const EmptyState(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Tidak ada laporan yang dilaporkan',
        subtitle: 'Tidak ada laporan yang ditandai bermasalah saat ini.',
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return ListView.separated(
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
                        onPressed: () {
                          scope.flagRepository.dismissFlag(flag.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Laporan penyalahgunaan diabaikan.',
                              ),
                            ),
                          );
                        },
                        child: const Text('Abaikan'),
                      ),
                      FilledButton.tonal(
                        onPressed: () {
                          if (report != null) {
                            scope.repository.setModerationStatus(
                              report.id,
                              ModerationStatus.hidden,
                            );
                            scope.flagRepository.resolveFlagsForReport(
                              report.id,
                              status: FlagReviewStatus.reviewed,
                            );
                          } else {
                            scope.flagRepository.reviewFlag(flag.id);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Laporan disembunyikan dan flag ditandai selesai.',
                              ),
                            ),
                          );
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
      return EmptyState(
        icon: Icons.assignment_turned_in_outlined,
        title: emptyMessage,
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return ListView.separated(
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
                        onPressed: () {
                          scope.repository.setModerationStatus(
                            r.id,
                            ModerationStatus.visible,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Laporan kini ditampilkan ke publik.',
                              ),
                            ),
                          );
                        },
                        child: const Text('Tampilkan'),
                      )
                    else
                      OutlinedButton(
                        onPressed: () {
                          scope.repository.setModerationStatus(
                            r.id,
                            ModerationStatus.hidden,
                          );
                          scope.flagRepository.resolveFlagsForReport(
                            r.id,
                            status: FlagReviewStatus.reviewed,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Laporan disembunyikan dan flag terkait ditandai selesai.',
                              ),
                            ),
                          );
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
