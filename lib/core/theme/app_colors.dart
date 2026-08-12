import 'package:flutter/material.dart';

/// Brand colors pulled from the Andalus login design.
/// Keep all hardcoded colors here so the rest of the app never
/// scatters raw Color(0x...) values everywhere.
class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF16213E); // Login button
  static const Color textDark = Color(0xFF1A1A1A); // "Welcome Back!"
  static const Color textGrey = Color(0xFF6B6B6B); // subtitle, labels, logo
  static const Color borderGrey = Color(0xFFCCCCCC); // input borders
  static const Color background = Colors.white;
}