import 'package:flutter/material.dart';

import '../navigation/shell_navigation_provider.dart';

/// Accent colors for each bottom-nav page.
class ShellPageColors {
  const ShellPageColors._();

  static const home = Color(0xFF2E7D32);
  static const products = Color(0xFF1565C0);
  static const sale = Color(0xFFE65100);
  static const history = Color(0xFF6A1B9A);
  static const settings = Color(0xFF00695C);

  static Color accentForTab(int index) => switch (index) {
        ShellTab.home => home,
        ShellTab.products => products,
        ShellTab.sale => sale,
        ShellTab.history => history,
        ShellTab.settings => settings,
        _ => home,
      };

  static ThemeData themeFor(BuildContext context, int tabIndex) {
    final base = Theme.of(context);
    final accent = accentForTab(tabIndex);
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: scheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      scaffoldBackgroundColor: Color.alphaBlend(
        accent.withValues(alpha: 0.06),
        Colors.white,
      ),
    );
  }
}
