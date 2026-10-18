import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Search bar with an icon, placeholder text, and an optional filter button.
///
/// Follows UI_UX_DESIGN.md §3: surface background, soft border, search icon,
/// clear placeholder.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.hintText = 'Cari nama barang...',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: onFilterTap != null
            ? IconButton(
                icon: const Icon(
                  Icons.tune_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: onFilterTap,
                tooltip: 'Filter',
              )
            : null,
      ),
    );
  }
}
