import 'package:flutter/material.dart';

/// High-contrast, accessibility-focused design system engineered for emergency stress conditions.
class EmergixxTheme {
  static const Color emergencyRed = Color(0xFFE53935);
  static const Color emergencyRedDark = Color(0xFFB71C1C);
  static const Color safeGreen = Color(0xFF2E7D32);
  static const Color safeGreenLight = Color(0xFF4CAF50);
  static const Color warningAmber = Color(0xFFF57F17);
  static const Color bgDark = Color(0xFF0F1115);
  static const Color surfaceDark = Color(0xFF1A1D24);
  static const Color surfaceCard = Color(0xFF222631);
  static const Color textPrimary = Color(0xFFF0F3F6);
  static const Color textSecondary = Color(0xFFA0A6B2);
  static const Color borderSubtle = Color(0xFF2D3342);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: emergencyRed,
        secondary: safeGreen,
        surface: surfaceDark,
        background: bgDark,
        error: emergencyRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emergencyRed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
