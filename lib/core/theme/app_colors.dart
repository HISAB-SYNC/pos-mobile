import 'package:flutter/material.dart';

/// Andalus POS Color Palette - High-contrast, clean slate color system.
class AppColors {
  AppColors._();

  // Primary & Brand Colors
  static const Color slateDark = Color(0xFF0F172A); // Main Slate Navy
  static const Color slateHeader = Color(0xFF1E293B); // Sub-header / Dark accents
  static const Color primaryBlue = Color(0xFF2563EB); // Electric Indigo Blue
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color accentIndigo = Color(0xFF4F46E5);

  // Status & Feedback Colors
  static const Color successEmerald = Color(0xFF059669); // Emerald Green
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warningAmber = Color(0xFFD97706); // Warm Amber
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color errorRose = Color(0xFFDC2626); // Coral Rose
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color infoBlue = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);

  // Text Colors
  static const Color textDark = Color(0xFF0F172A); // Main Title & Body text
  static const Color textMedium = Color(0xFF475569); // Subtitles & secondary labels
  static const Color textMuted = Color(0xFF94A3B8); // Captions, placeholders
  static const Color textLight = Colors.white;

  // Background & Surface Colors
  static const Color background = Color(0xFFF8FAFC); // Slate background
  static const Color cardSurface = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0); // Card & input border
  static const Color borderMedium = Color(0xFFCBD5E1);
  static const Color inputBackground = Color(0xFFF1F5F9);

  // Deprecated compatibility aliases
  static const Color navy = slateDark;
  static const Color textGrey = textMedium;
  static const Color borderGrey = borderLight;
}