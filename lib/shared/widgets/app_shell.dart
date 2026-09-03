import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/shell_navigation_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shell_page_colors.dart';
import 'offline_status_banner.dart';

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}

/// Mobile-first bottom-navigation shell for the protected area of the
/// app.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.destinations});

  final List<ShellDestination> destinations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellNavigationIndexProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const OfflineStatusBanner(),
            Expanded(
              child: IndexedStack(
                index: index,
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Theme(
                      data: ShellPageColors.themeFor(context, i),
                      child: destinations[i].screen,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ShellNavigationBar(
        key: const Key('shell_bottom_nav'),
        destinations: destinations,
        selectedIndex: index.clamp(0, destinations.length - 1),
        onDestinationSelected: (i) =>
            ref.read(shellNavigationIndexProvider.notifier).state = i,
      ),
    );
  }
}

class ShellNavigationBar extends StatelessWidget {
  const ShellNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.navigationBarTheme;
    final colorScheme = theme.colorScheme;
    final height = navTheme.height ?? AppTheme.shellNavigationBarHeight;

    return Material(
      elevation: 3,
      color: navTheme.backgroundColor ?? colorScheme.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _ShellNavItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    accentColor: ShellPageColors.accentForTab(i),
                    onTap: () => onDestinationSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.destination,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? accentColor : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected
                    ? accentColor.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: true,
              ),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    height: 1.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
