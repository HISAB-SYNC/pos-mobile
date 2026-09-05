import 'package:flutter/material.dart';

/// Andalus POS Color Palette - High-contrast, clean slate color system.
class AppColors {
  AppColors._();

  // Signature Theme Brand Colors (#C0E763)
  static const Color brandLime = Color(0xFFC0E763); // Signature Vibrant Electric Lime (Main Theme)
  static const Color brandLimeDark = Color(0xFFA6D43B); // Deeper Lime Accent / Pressed state / Active Borders
  static const Color brandLimeDeep = Color(0xFF456B08); // High-contrast forest/olive lime for text/icons on light surfaces
  static const Color brandLimeLight = Color(0xFFE4F8A6); // Medium Lime Tint
  static const Color brandLimeBg = Color(0xFFF4FBE4); // Light Tinted Lime Surface
  static const Color brandLimeBorder = Color(0xFFC7EC6F); // Lime Accent Border
  static const Color brandLimeDarkText = Color(0xFF121E05); // Ultra-dark high-contrast text for lime buttons/badges
  static const Color brandLimeGlow = Color(0x4DC0E763); // Soft ambient lime glow

  // Primary Theme Aliases (pointing to brand lime suite)
  static const Color primary = brandLime;
  static const Color primaryDark = brandLimeDark;
  static const Color primaryDeep = brandLimeDeep;
  static const Color primaryLight = brandLimeBg;
  static const Color primaryBorder = brandLimeBorder;

  // Compatibility aliases redirecting primaryBlue to brandLimeDeep for instant harmonious styling
  static const Color primaryBlue = brandLimeDeep;
  static const Color primaryBlueDark = Color(0xFF355405);
  static const Color accentIndigo = Color(0xFF456B08);

  // Gradient stops pairing with brandLime
  static const Color gradientDarkPine = Color(0xFF0D2818); // Deep Forest Pine
  static const Color gradientEmerald = Color(0xFF1B4332);  // Rich Emerald
  static const Color gradientLimeGlow = Color(0x3DC0E763); // Soft Lime Glow

  // Dark Slate & Header Accents
  static const Color slateDark = Color(0xFF0F172A); // Main Slate Navy
  static const Color slateHeader = Color(0xFF1E293B); // Sub-header / Dark accents

  // Status & Feedback Colors
  static const Color successEmerald = Color(0xFF15803D); // Forest Emerald Green
  static const Color successBg = Color(0xFFF0FDF4);
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

  // Background & Surface Colors (warm organic tint rather than sterile hospital white)
  static const Color background = Color(0xFFF7FAF2); // Fresh ambient background
  static const Color cardSurface = Colors.white;
  static const Color borderLight = Color(0xFFE2EBD5); // Card & input border
  static const Color borderMedium = Color(0xFFCBD5C5);
  static const Color inputBackground = Color(0xFFEFF5E7);

  // Deprecated compatibility aliases
  static const Color navy = slateDark;
  static const Color textGrey = textMedium;
  static const Color borderGrey = borderLight;
}