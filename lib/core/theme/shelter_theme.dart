import 'package:flutter/material.dart';

/// ShelterTheme provides a high-contrast, emergency-optimized dark theme 
/// matching the HCI Milestone 02 design specifications.
class ShelterTheme {
  // ----------------------------------------
  // Core Color Palette (HCI Milestone 02)
  // ----------------------------------------
  
  /// Deep Navy / True Black
  static const Color backgroundDeepNavy = Color(0xFF0B132B);
  
  /// Dark Navy for cards and general surfaces
  static const Color surfaceDarkNavy = Color(0xFF1C2541);
  
  /// Lighter Navy for elevated surfaces or active states
  static const Color surfaceLightNavy = Color(0xFF273456);

  /// Primary Action Color (High visibility)
  static const Color primaryActionOrange = Color(0xFFFF6B35);

  // Status Colors
  static const Color statusSafeGreen = Color(0xFF06D6A0);
  static const Color statusWarningYellow = Color(0xFFFFD166);
  static const Color statusCriticalRed = Color(0xFFEF476F);

  // Text Colors
  static const Color textHighContrastWhite = Color(0xFFF8F9FA);
  static const Color textMuted = Color(0xFF90A4AE);

  // ----------------------------------------
  // ThemeData Getter
  // ----------------------------------------
  
  /// Returns the complete ThemeData configured for the Shelter Relief Tracker.
  static ThemeData get darkTheme {
    return ThemeData(
      // Baseline theme setup
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      
      // Color Scheme
      scaffoldBackgroundColor: backgroundDeepNavy,
      colorScheme: const ColorScheme.dark(
        primary: primaryActionOrange,
        secondary: statusSafeGreen,
        surface: surfaceDarkNavy,
        error: statusCriticalRed,
        onPrimary: textHighContrastWhite,
        onSecondary: backgroundDeepNavy, // contrast against bright green
        onSurface: textHighContrastWhite,
        onError: textHighContrastWhite,
      ),

      // Text Theme matching UI specifications
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textHighContrastWhite, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textHighContrastWhite, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textHighContrastWhite, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textHighContrastWhite, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: textHighContrastWhite, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textHighContrastWhite, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textHighContrastWhite, fontSize: 16),
        bodyMedium: TextStyle(color: textHighContrastWhite, fontSize: 14),
        bodySmall: TextStyle(color: textMuted, fontSize: 12),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceDarkNavy,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDeepNavy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textHighContrastWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        iconTheme: IconThemeData(color: textHighContrastWhite),
      ),

      // Button Theme (Wet-touch friendly, minimum 52px height)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryActionOrange,
          foregroundColor: textHighContrastWhite,
          minimumSize: const Size(double.infinity, 52), // Wet-touch friendly target
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryActionOrange,
        foregroundColor: textHighContrastWhite,
        elevation: 4,
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLightNavy,
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryActionOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDarkNavy,
        selectedItemColor: primaryActionOrange,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
