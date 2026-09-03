import 'package:flutter/material.dart';

/// Minimal theme for Phase 0. Kept intentionally simple — visual
/// polish, Bengali typography, and dark mode are addressed in a later
/// phase, not here.
class AppTheme {
  const AppTheme._();

  /// Bottom shell nav height — tall enough for Bengali labels with descenders.
  static const double shellNavigationBarHeight = 80;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      navigationBarTheme: const NavigationBarThemeData(
        height: shellNavigationBarHeight,
      ),
    );
  }
}
