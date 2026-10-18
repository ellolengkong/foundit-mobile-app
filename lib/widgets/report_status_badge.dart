import 'package:flutter/material.dart';

import '../core/constants/report_enums.dart';

/// Small badge indicating the lifecycle status of a report (Aktif vs Selesai).
///
/// Kept visually distinct from [StatusChip] which indicates [ReportType] (Hilang/Ditemukan).
class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final isResolved = status == ReportStatus.resolved;
    final bgColor = isResolved
        ? const Color(0xFFF1F1F4)
        : const Color(0xFFE6F4EA);
    final textColor = isResolved
        ? const Color(0xFF6B7280)
        : const Color(0xFF137333);
    final icon = isResolved
        ? Icons.check_circle_outline
        : Icons.radio_button_checked;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
