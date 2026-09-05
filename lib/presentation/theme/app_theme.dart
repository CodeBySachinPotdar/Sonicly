import 'package:flutter/material.dart';

class AppTheme {
  static const Color accentColor = Color(0xFF6366F1); // Indigo accent
  static const Color accentSecondary = Color(0xFF06B6D4); // Cyan accent

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: accentSecondary,
        surface: const Color(0xFFF8FAFC),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF1F5F9),
        surfaceContainer: const Color(0xFFE2E8F0),
        onSurface: const Color(0xFF0F172A),
        onSurfaceVariant: const Color(0xFF475569),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: const Color(0xFFE2E8F0),
        thumbColor: accentColor,
        overlayColor: accentColor.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
    );
  }

  static ThemeData darkTheme({bool isAmoled = false}) {
    final bgColor = isAmoled ? Colors.black : const Color(0xFF0F172A);
    final surfaceColor = isAmoled ? const Color(0xFF111111) : const Color(0xFF1E293B);
    final cardColor = isAmoled ? const Color(0xFF161616) : const Color(0xFF1E293B);
    final borderColor = isAmoled ? const Color(0xFF222222) : const Color(0xFF334155);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF818CF8),
        secondary: const Color(0xFF22D3EE),
        surface: surfaceColor,
        surfaceContainerLowest: bgColor,
        surfaceContainerLow: isAmoled ? const Color(0xFF0A0A0A) : const Color(0xFF162032),
        surfaceContainer: cardColor,
        onSurface: const Color(0xFFF8FAFC),
        onSurfaceVariant: const Color(0xFF94A3B8),
      ),
      scaffoldBackgroundColor: bgColor,
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF818CF8),
        inactiveTrackColor: const Color(0xFF334155),
        thumbColor: const Color(0xFF818CF8),
        overlayColor: const Color(0xFF818CF8).withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
    );
  }
}
