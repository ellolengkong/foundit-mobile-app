import 'package:flutter/material.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';

/// Horizontally scrollable row of category filter chips (pill shape).
///
/// - Inactive: neutral background with border.
/// - Active: `primarySoft` background with `primary` text.
///
/// An "all" chip is prepended so the user can clear the category filter.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selectedKey,
    required this.onSelected,
  });

  /// Currently selected category key, or `null` for "Semua".
  final String? selectedKey;

  /// Called with the selected key, or `null` when "Semua" is tapped.
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: kCategories.length + 1, // +1 for "Semua"
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Chip(
              label: 'Semua',
              isSelected: selectedKey == null,
              onTap: () => onSelected(null),
            );
          }
          final cat = kCategories[index - 1];
          return _Chip(
            label: cat.label,
            icon: cat.icon,
            isSelected: selectedKey == cat.key,
            onTap: () => onSelected(cat.key),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
