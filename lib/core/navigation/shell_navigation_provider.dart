import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-navigation tab indices — must stay aligned with
/// [AppShell] destinations in `app_router.dart`.
abstract final class ShellTab {
  static const int home = 0;
  static const int products = 1;
  static const int sale = 2;
  static const int stockIn = 3;
  static const int history = 4;
  static const int settings = 5;
}

/// Selected tab for the protected [AppShell]. Quick actions on the
/// dashboard update this provider to switch tabs without pushing routes.
final shellNavigationIndexProvider = StateProvider<int>((ref) => ShellTab.home);
