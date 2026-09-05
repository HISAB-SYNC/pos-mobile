import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized UI component decorations & styling helpers.
class AppDecorations {
  AppDecorations._();

  /// Soft shadow for elevated cards & containers
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ];

  /// Elevated card decoration with 16px corner radius and subtle organic border
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: cardShadow,
      );

  /// Subtle outline card decoration (flat)
  static BoxDecoration get outlineCardDecoration => BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
      );

  /// Soft tinted card decoration for stats and metrics
  static BoxDecoration softCardDecoration({
    required Color backgroundColor,
    Color? borderColor,
    double borderRadius = 16,
  }) =>
      BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.borderLight.withOpacity(0.6),
          width: 1,
        ),
      );

  /// Pill button / container decoration
  static BoxDecoration pillDecoration({
    Color backgroundColor = AppColors.inputBackground,
    Color? borderColor,
  }) =>
      BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
      );

  /// Floating bottom action bar decoration
  static BoxDecoration get floatingBarDecoration => BoxDecoration(
        color: AppColors.slateDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandLime.withValues(alpha: 0.28), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x1CC0E763),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      );

  /// Input decoration for TextFields across forms
  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: AppColors.textMuted,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandLimeDark, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorRose, width: 1),
      ),
    );
  }
}
