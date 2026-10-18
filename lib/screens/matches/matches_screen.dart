import 'package:flutter/material.dart';

import '../../core/constants/report_enums.dart';
import '../../core/services/matching_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/foundit_scope.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';
import '../home/report_detail_screen.dart';

/// Screen displaying scored potential matches between lost and found items.
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = FoundItScope.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kemungkinan Cocok')),
      body: ListenableBuilder(
        listenable: scope.repository,
        builder: (context, _) {
          final reports = scope.repository.getPublicReports();
          final matches = MatchingService.findMatches(reports);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Deterministic Matching Disclaimer Banner ─────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sistem Pencocokan Deterministik',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Skor kecocokan dihitung berdasarkan kategori (30), kata kunci (30), lokasi (25), dan kedekatan tanggal (15) dengan ambang awal 60/100. Skor ini bukan kepastian; harap verifikasi ciri rahasia kepemilikan secara langsung.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (matches.isEmpty)
                const EmptyState(
                  icon: Icons.auto_awesome_motion_outlined,
                  title: 'Belum Ada Kecocokan',
                  subtitle: 'Belum ada laporan yang cocok dengan ambang skor minimal 60/100. Periksa kembali nanti.',
                )
              else ...[
                Text(
                  'Ditemukan ${matches.length} Kemungkinan Cocok',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...matches.map(
                  (pair) => _buildMatchCard(context, pair, textTheme),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    MatchPair pair,
    TextTheme textTheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pair.score >= 80
                        ? AppColors.foundSoft
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Skor ${pair.score}/100',
                    style: textTheme.labelMedium?.copyWith(
                      color: pair.score >= 80
                          ? AppColors.found
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  pair.lost.campusArea,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Breakdown row
            Text(
              'Rincian: Kategori ${pair.breakdown.categoryScore} • Kata kunci ${pair.breakdown.keywordScore} • Lokasi ${pair.breakdown.locationScore} • Tanggal ${pair.breakdown.dateScore}',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const Divider(height: 18),

            // Lost item preview
            Row(
              children: [
                const StatusChip(reportType: ReportType.lost),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pair.lost.itemName,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ReportDetailScreen(reportId: pair.lost.id),
                      ),
                    );
                  },
                  child: const Text('Detail'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Found item preview
            Row(
              children: [
                const StatusChip(reportType: ReportType.found),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pair.found.itemName,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ReportDetailScreen(reportId: pair.found.id),
                      ),
                    );
                  },
                  child: const Text('Detail'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
