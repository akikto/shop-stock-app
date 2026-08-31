import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/shell_navigation_provider.dart';
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
                children: [for (final d in destinations) d.screen],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index.clamp(0, destinations.length - 1),
        onDestinationSelected: (i) =>
            ref.read(shellNavigationIndexProvider.notifier).state = i,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
