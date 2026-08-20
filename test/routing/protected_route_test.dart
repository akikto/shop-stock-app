import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/core/routing/app_router.dart';
import 'package:shop_stock_app/features/auth/providers/auth_provider.dart';
import 'package:shop_stock_app/features/products/providers/product_providers.dart';
import 'package:shop_stock_app/repositories/product_repository.dart';
import 'package:shop_stock_app/models/profile.dart';
import 'package:shop_stock_app/models/user_role.dart';

import '../auth/fake_auth_repository.dart';

Widget _appWithRouter(FakeAuthRepository fake) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fake),
      productListControllerProvider.overrideWith((ref) {
        return _FakeProductListController();
      }),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

/// A no-op controller that never touches Supabase, so the protected shell
/// can render in tests without a live database connection.
class _FakeProductListController extends ProductListController {
  _FakeProductListController() : super(_NoOpProductRepository());
  @override
  Future<void> loadFirstPage() async {}
  @override
  Future<void> loadMore() async {}
  @override
  Future<void> setSearchQuery(String query) async {}
  @override
  Future<void> refresh() async {}
}

class _NoOpProductRepository implements ProductRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('protected route redirects', () {
    testWidgets('unauthenticated user is redirected to Login and never sees the app shell',
        (tester) async {
      final fake = FakeAuthRepository(signedIn: false);
      addTearDown(fake.dispose);

      await tester.pumpWidget(_appWithRouter(fake));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.login), findsOneWidget);
      // Bottom navigation (protected shell) must not be present.
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('authenticated user with an active profile reaches the protected shell',
        (tester) async {
      final fake = FakeAuthRepository(
        signedIn: true,
        profile: Profile(
          id: 'user-1',
          name: 'Staff Member',
          role: UserRole.staff,
          isActive: true,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      addTearDown(fake.dispose);

      await tester.pumpWidget(_appWithRouter(fake));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text(AppStrings.login), findsNothing);
    });

    testWidgets('authenticated but deactivated account is blocked from the shell with a clear message',
        (tester) async {
      final fake = FakeAuthRepository(
        signedIn: true,
        profile: Profile(
          id: 'user-2',
          name: 'Disabled Staff',
          role: UserRole.staff,
          isActive: false,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      addTearDown(fake.dispose);

      await tester.pumpWidget(_appWithRouter(fake));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.textContaining(AppStrings.accountDeactivated), findsOneWidget);
    });
  });
}
