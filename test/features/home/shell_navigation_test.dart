import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/navigation/shell_navigation_provider.dart';
import 'package:shop_stock_app/models/user_role.dart';

void main() {
  group('Shell navigation', () {
    test('tab indices align with app shell destinations', () {
      expect(ShellTab.home, 0);
      expect(ShellTab.products, 1);
      expect(ShellTab.sale, 2);
      expect(ShellTab.stockIn, 3);
      expect(ShellTab.history, 4);
      expect(ShellTab.settings, 5);
    });

    test('shellNavigationIndexProvider updates selected tab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(shellNavigationIndexProvider), ShellTab.home);

      container.read(shellNavigationIndexProvider.notifier).state = ShellTab.sale;
      expect(container.read(shellNavigationIndexProvider), 2);

      container.read(shellNavigationIndexProvider.notifier).state =
          ShellTab.stockIn;
      expect(container.read(shellNavigationIndexProvider), 3);

      container.read(shellNavigationIndexProvider.notifier).state =
          ShellTab.history;
      expect(container.read(shellNavigationIndexProvider), 4);
    });
  });

  group('Reports role gate', () {
    test('only owner and manager can view reports', () {
      expect(UserRole.owner.canViewReports, isTrue);
      expect(UserRole.manager.canViewReports, isTrue);
      expect(UserRole.staff.canViewReports, isFalse);
    });
  });
}
