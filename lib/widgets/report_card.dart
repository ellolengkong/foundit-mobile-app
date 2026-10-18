import 'package:flutter/material.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';
import '../data/models/report.dart';
import 'status_chip.dart';

/// A card displaying a single report in the feed.
///
/// Layout (from UI_UX_DESIGN.md §3):
/// ```
/// +--------+  Item name
/// |  FOTO  |  [StatusChip]
/// |        |  Campus area · Building
/// +--------+  Date
/// ```
///
/// Tapping the card calls [onTap].
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report, this.onTap});

  final Report report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoryLabel =
        categoryByKey(report.category)?.label ?? report.category;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo placeholder ─────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),

              // ── Info column ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name
                    Text(
                      report.itemName,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Type chip
                    StatusChip(reportType: report.reportType),
                    const SizedBox(height: 6),

                    // Category
                    Text(
                      categoryLabel,
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Location
                    Text(
                      _locationText(),
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Date
                    Text(_dateText(), style: textTheme.labelSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _locationText() {
    if (report.buildingName != null &&
        report.buildingName!.isNotEmpty &&
        report.buildingName != 'Tidak tahu') {
      return '${report.campusArea} · ${report.buildingName}';
    }
    return report.campusArea;
  }

  String _dateText() {
    final d = report.eventDate;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
