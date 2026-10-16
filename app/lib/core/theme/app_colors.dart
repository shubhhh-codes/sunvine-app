import 'package:flutter/material.dart';

class AppColors {
  // Brand Canvas & Surfaces
  static const Color canvas = Color(0xFF070D18);
  static const Color surface = Color(0xFF0D1527);
  static const Color surfaceHover = Color(0xFF131F38);
  static const Color surfaceSubtle = Color(0xFF111C35);

  // Borders & Dividers
  static const Color border = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFF334155);

  // Energy Gradient (emerald-600 → teal-500)
  static const Color emerald600 = Color(0xFF059669);
  static const Color teal500 = Color(0xFF14B8A6);
  static const LinearGradient energyGradient = LinearGradient(
    colors: [emerald600, teal500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Accent Colors
  static const Color emerald = Color(0xFF10B981);
  static const Color teal = Color(0xFF14B8A6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFEF4444);
  static const Color cyan = Color(0xFF06B6D4);

  // Typography Palette
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  // Functional Surfaces
  static const Color cardShadow = Color(0x66000000);
  static const Color inputBackground = Color(0xFF0A1120);
}
