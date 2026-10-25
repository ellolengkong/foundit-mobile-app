import 'package:flutter/material.dart';

import '../core/constants/categories.dart';
import '../core/constants/report_enums.dart';
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: 96,
                  height: 108,
                  child: report.publicPhotoUrl != null
                      ? Image.network(
                          report.publicPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _PhotoPlaceholder(report: report),
                        )
                      : _PhotoPlaceholder(report: report),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusChip(reportType: report.reportType),
                        const Spacer(),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 17,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      report.itemName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      categoryLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _locationText(),
                            style: textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(_dateText(), style: textTheme.labelSmall),
                      ],
                    ),
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

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final isFound = report.reportType == ReportType.found;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFound
              ? [AppColors.foundSoft, const Color(0xFFD2EEE7)]
              : [AppColors.lostSoft, const Color(0xFFFFE2D2)],
        ),
      ),
      child: Center(
        child: Icon(
          isFound ? Icons.inventory_2_outlined : Icons.search_rounded,
          color: isFound ? AppColors.found : AppColors.lost,
          size: 34,
        ),
      ),
    );
  }
}
