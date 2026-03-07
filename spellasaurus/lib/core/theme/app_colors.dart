import 'package:flutter/material.dart';

/// Spellasaurus colour palette
abstract class AppColors {
  // Primary — bright purple
  static const primary = Color(0xFF6C3CE1);
  static const primaryLight = Color(0xFF9B6FF5);
  static const primaryDark = Color(0xFF4A1DB8);

  // Secondary — sunny yellow
  static const secondary = Color(0xFFFFC832);
  static const secondaryLight = Color(0xFFFFD966);
  static const secondaryDark = Color(0xFFE6A800);

  // Accent — coral
  static const accent = Color(0xFFFF6B6B);
  static const accentGreen = Color(0xFF4CAF82);

  // Backgrounds
  static const bgLight = Color(0xFFF8F4FF);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgDark = Color(0xFF1A1035);

  // Surfaces (dark mode)
  static const surfaceDark = Color(0xFF251845);
  static const cardDark = Color(0xFF32205C);

  // Text
  static const textDark = Color(0xFF1A1035);
  static const textMedium = Color(0xFF5A5175);
  static const textLight = Color(0xFF9B96B0);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const success = Color(0xFF4CAF82);
  static const error = Color(0xFFFF5252);
  static const warning = Color(0xFFFFB74D);

  // Stars
  static const starFilled = Color(0xFFFFC832);
  static const starEmpty = Color(0xFFE0D9F0);
}
