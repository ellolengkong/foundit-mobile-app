import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography system from UI_UX_DESIGN.md §3.
///
/// Font: Plus Jakarta Sans (via google_fonts).
/// Sizes: page title 24sp, section title 18sp, card title 16sp,
///        body 14-16sp, metadata 12-13sp.
abstract class AppTypography {
  /// Base text theme using Plus Jakarta Sans.
  static TextTheme get textTheme {
    return GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(
        // ── Page title — 24sp semi-bold ──────────────────────────────────
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
        ),

        // ── Section title — 18sp semi-bold ──────────────────────────────
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
        ),

        // ── Card title — 16sp semi-bold ─────────────────────────────────
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),

        // ── Body large — 16sp regular ───────────────────────────────────
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),

        // ── Body medium — 14sp regular ──────────────────────────────────
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),

        // ── Body small — 13sp (metadata) ────────────────────────────────
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.4,
        ),

        // ── Label large — buttons / chips ───────────────────────────────
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),

        // ── Label small — tiny metadata — 12sp ──────────────────────────
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.3,
        ),
      ),
    );
  }
}
