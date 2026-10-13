import 'package:flutter/material.dart';

/// WeSafe design tokens.
///
/// A high-contrast, battery-saving palette built for disaster and
/// emergency conditions (dark surfaces, vivid semantic colours).
class AppColors {
  AppColors._();

  // ── Backgrounds: Deep Navy / True Black (saves battery, cuts glare) ──
  static const Color trueBlack = Color(0xFF000000);
  static const Color backgroundDeep = Color(0xFF0B1220);
  static const Color background = Color(0xFF0B1220); // Deep Navy
  static const Color surface = Color(0xFF131C2E);
  static const Color surfaceElevated = Color(0xFF1C2740);
  static const Color border = Color(0xFF2B3A55);

  // ── Primary action: Bright Orange ("Report Hazard", "Start Navigating") ──
  static const Color primary = Color(0xFF38BDF8);
  static const Color primaryLight = Color(0xFF7DD3FC);
  static const Color primaryDark = Color(0xFF0EA5E9);

  // ── Text: White / Light Grey ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC9D1DE);
  static const Color textMuted = Color(0xFFB6C2D6);

  // ── Success & Safety: Green (safe routes, shelter check-ins, supplies OK) ──
  static const Color success = Color(0xFF34D399);

  // ── Warning: Yellow / Orange (moderate hazards, low stock) ──
  static const Color warning = Color(0xFFFBBF24);

  // ── Emergency & Critical: Red ("Evacuate Now", severe hazards) ──
  static const Color critical = Color(0xFFF87171);
}
