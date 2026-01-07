import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeType { nord, parchment, newspaper }

class AppTheme {
  // Nord-inspired Palette
  static const Color polarNight1 = Color(0xFF2E3440);
  static const Color polarNight2 = Color(0xFF3B4252);
  static const Color snowStorm1 = Color(0xFFD8DEE9);
  static const Color frost1 = Color(0xFF8FBCBB);
  static const Color frost3 = Color(0xFF81A1C1);
  static const Color auroraRed = Color(0xFFBF616A);

  // Parchment Palette (warm, aged paper)
  static const Color parchmentBg = Color(0xFFF5E6C8);
  static const Color parchmentSurface = Color(0xFFEAD9B5);
  static const Color parchmentText = Color(0xFF3D2B1F);
  static const Color parchmentAccent = Color(0xFF8B4513);
  static const Color parchmentSecondary = Color(0xFFA0522D);

  // Newspaper Palette (high contrast, classic)
  static const Color newspaperBg = Color(0xFFFAFAF8);
  static const Color newspaperSurface = Color(0xFFEEEEEC);
  static const Color newspaperText = Color(0xFF1A1A1A);
  static const Color newspaperAccent = Color(0xFF2F2F2F);
  static const Color newspaperRed = Color(0xFFC41E3A);

  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.nord:
        return _nordTheme;
      case AppThemeType.parchment:
        return _parchmentTheme;
      case AppThemeType.newspaper:
        return _newspaperTheme;
    }
  }

  static ThemeData get _nordTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: polarNight1,
      colorScheme: const ColorScheme.dark(
        primary: frost1,
        secondary: frost3,
        surface: polarNight2,
        error: auroraRed,
        onSurface: snowStorm1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: polarNight1,
        elevation: 0,
        titleTextStyle: TextStyle(color: snowStorm1, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: polarNight2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: snowStorm1.withValues(alpha: 0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: frost1,
          foregroundColor: polarNight1,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static ThemeData get _parchmentTheme {
    final textTheme = GoogleFonts.loraTextTheme().apply(
      bodyColor: parchmentText,
      displayColor: parchmentText,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: parchmentBg,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: parchmentAccent,
        secondary: parchmentSecondary,
        surface: parchmentSurface,
        error: Color(0xFF8B0000),
        onSurface: parchmentText,
        onPrimary: parchmentBg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: parchmentBg,
        elevation: 0,
        titleTextStyle: GoogleFonts.lora(
          color: parchmentText,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: parchmentText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: parchmentSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: parchmentAccent.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: parchmentAccent.withValues(alpha: 0.3)),
        ),
        hintStyle: TextStyle(color: parchmentText.withValues(alpha: 0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: parchmentAccent,
          foregroundColor: parchmentBg,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.lora(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: parchmentText),
    );
  }

  static ThemeData get _newspaperTheme {
    final textTheme = GoogleFonts.playfairDisplayTextTheme().apply(
      bodyColor: newspaperText,
      displayColor: newspaperText,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: newspaperBg,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: newspaperAccent,
        secondary: newspaperText,
        surface: newspaperSurface,
        error: newspaperRed,
        onSurface: newspaperText,
        onPrimary: newspaperBg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: newspaperBg,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: newspaperText,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: const IconThemeData(color: newspaperText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: newspaperSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(color: newspaperText, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: newspaperText.withValues(alpha: 0.3), width: 1),
        ),
        hintStyle: TextStyle(color: newspaperText.withValues(alpha: 0.4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: newspaperText,
          foregroundColor: newspaperBg,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          textStyle: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(color: newspaperText, thickness: 1),
      iconTheme: const IconThemeData(color: newspaperText),
    );
  }

  // Keep for backward compatibility
  static ThemeData get theme => _nordTheme;
}
