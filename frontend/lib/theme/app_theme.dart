import 'package:flutter/material.dart';

/// App-wide design tokens for the Strixhaven encounter manager.
abstract class AppTheme {
  // Palette — dark arcane aesthetic
  static const Color background = Color(0xFF0D0F1A);
  static const Color surface = Color(0xFF161929);
  static const Color surfaceVariant = Color(0xFF1E2236);
  static const Color border = Color(0xFF2A2F4A);

  static const Color playerGreen = Color(0xFF2DD4A0);
  static const Color playerGreenDim = Color(0xFF183D30);
  static const Color monsterRed = Color(0xFFE05252);
  static const Color monsterRedDim = Color(0xFF3D1818);

  static const Color accent = Color(0xFF7C6AF7);        // purple
  static const Color accentGlow = Color(0x337C6AF7);
  static const Color gold = Color(0xFFE8C56B);

  static const Color textPrimary = Color(0xFFEEF0FF);
  static const Color textSecondary = Color(0xFF8A90B4);
  static const Color textMuted = Color(0xFF4A5070);

  static const Color hpFull = Color(0xFF2DD4A0);
  static const Color hpMid = Color(0xFFE8C56B);
  static const Color hpLow = Color(0xFFE05252);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: playerGreen,
          surface: surface,
          onSurface: textPrimary,
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(
              color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
          labelSmall: TextStyle(color: textMuted, fontSize: 11),
        ),
        cardTheme: CardThemeData(
          color: surfaceVariant,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: border, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      );
}
