import 'package:flutter/material.dart';

/// Design tokens from UI_UX_DESIGN.md §2 — Indigo + Soft Neutral palette.
///
/// Usage rules (from the spec):
/// - `background` for page backgrounds, `surface` for cards/forms.
/// - `primary` selectively: one main CTA per screen.
/// - Lost/found chips always include a text label, not color alone.
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const primary = Color(0xFF5B5BD6);
  static const primaryPressed = Color(0xFF4545B8);
  static const primarySoft = Color(0xFFEEEEFF);

  // ── Surfaces ───────────────────────────────────────────────────────────
  static const background = Color(0xFFF7F7FB);
  static const surface = Color(0xFFFFFFFF);

  // ── Text ────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF202033);
  static const textSecondary = Color(0xFF717187);

  // ── Borders ─────────────────────────────────────────────────────────────
  static const border = Color(0xFFE7E7F0);

  // ── Report type: Found ──────────────────────────────────────────────────
  static const found = Color(0xFF167D72);
  static const foundSoft = Color(0xFFE5F5F1);

  // ── Report type: Lost ───────────────────────────────────────────────────
  static const lost = Color(0xFFB95D32);
  static const lostSoft = Color(0xFFFFF0E8);

  // ── Feedback ────────────────────────────────────────────────────────────
  static const error = Color(0xFFC43D4B);
  static const success = Color(0xFF18794E);
}
