import 'package:flutter/material.dart';

import '../core/constants/report_enums.dart';
import '../core/theme/app_colors.dart';

/// Pill-shaped chip that displays a [ReportType] label with the correct color.
///
/// - **Hilang**: `lostSoft` background, `lost` text.
/// - **Ditemukan**: `foundSoft` background, `found` text.
///
/// This widget represents *what kind of report* it is — not the lifecycle
/// status (active/resolved) or moderation status (visible/hidden).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.reportType});

  final ReportType reportType;

  @override
  Widget build(BuildContext context) {
    final bool isLost = reportType == ReportType.lost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLost ? AppColors.lostSoft : AppColors.foundSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        reportType.shortLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isLost ? AppColors.lost : AppColors.found,
        ),
      ),
    );
  }
}
