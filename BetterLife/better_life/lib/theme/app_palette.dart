import 'package:flutter/material.dart';

class AppPalette {
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentOrange = Color(0xFFFB923C);
  static const Color accentTeal = Color(0xFF2DD4BF);

  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF171A22);
  static const Color darkInput = Color(0xFF10131A);

  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Colors.white;
  static const Color lightInput = Color(0xFFF1F5F9);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color background(BuildContext context) {
    return isDark(context) ? darkBackground : lightBackground;
  }

  static Color surface(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  static Color input(BuildContext context) {
    return isDark(context) ? darkInput : lightInput;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? Colors.white10 : const Color(0xFFE2E8F0);
  }

  static Color primaryText(BuildContext context) {
    return isDark(context) ? Colors.white : const Color(0xFF0F172A);
  }

  static Color secondaryText(BuildContext context) {
    return isDark(context) ? Colors.white60 : const Color(0xFF64748B);
  }

  static const LinearGradient heroGradient = LinearGradient(
    colors: [accentPurple, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}