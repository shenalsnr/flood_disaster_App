import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Global dark, high-contrast theme for WeSafe.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.trueBlack,
      secondary: AppColors.success,
      onSecondary: AppColors.trueBlack,
      tertiary: AppColors.warning,
      error: AppColors.critical,
      onError: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDeep,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.trueBlack,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
      ),
    );
  }
}
