import 'package:flutter/material.dart';

/// WeSafe design tokens.
///
/// A high-contrast, battery-saving palette built for disaster and
/// emergency conditions (dark surfaces, vivid semantic colours).
class AppColors {
  AppColors._();

  // ── Backgrounds: Deep Navy / True Black (saves battery, cuts glare) ──
  static const Color trueBlack = Color(0xFF000000);
  static const Color backgroundDeep = Color(0xFF070B14);
  static const Color background = Color(0xFF070B14); // Deep Navy
  static const Color surface = Color(0xFF131B2B);
  static const Color surfaceElevated = Color(0xFF1E293B);
  static const Color border = Color(0xFF334155);

  // ── Primary action: Bright Orange ("Report Hazard", "Start Navigating") ──
  static const Color primary = Color(0xFFFF6D00);
  static const Color primaryLight = Color(0xFFFF8F5A);
  static const Color primaryDark = Color(0xFFE5500F);

  // ── Text: White / Light Grey ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC9D1DE);
  static const Color textMuted = Color(0xFF8C97AB);

  // ── Success & Safety: Green (safe routes, shelter check-ins, supplies OK) ──
  static const Color success = Color(0xFF00E676);

  // ── Warning: Yellow / Orange (moderate hazards, low stock) ──
  static const Color warning = Color(0xFFFFC107);

  // ── Emergency & Critical: Red ("Evacuate Now", severe hazards) ──
  static const Color critical = Color(0xFFFF1744);
}
