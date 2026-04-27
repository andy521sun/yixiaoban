import 'package:flutter/material.dart';

class AdminTheme {
  static const Color primary = Color(0xFF34A853);
  static const Color primaryDark = Color(0xFF2E7D32);
  static const Color accent = Color(0xFF1A73E8);
  static const Color error = Color(0xFFDB4437);
  static const Color warning = Color(0xFFF4B400);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color cardBorder = Color(0xFFE8EAED);
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: bgColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelType: NavigationRailLabelType.all,
      ),
    );
  }
}
