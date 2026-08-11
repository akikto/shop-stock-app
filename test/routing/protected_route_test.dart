import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/routing/app_router.dart';
import 'package:shop_stock_app/features/auth/providers/auth_provider.dart';
import 'package:shop_stock_app/models/profile.dart';
import 'package:shop_stock_app/models/user_role.dart';

import '../auth/fake_auth_repository.dart';

Widget _appWithRouter(FakeAuthRepository fake) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(fake)],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

void main() {
  group('protected route redirects', () {
    testWidgets('unauthenticated user is redirected to Login and never sees the app shell',
        (tester) async {
      final fake = FakeAuthRepository(signedIn: false);
      addTearDown(fake.dispose);

      await tester.pumpWidget(_appWithRouter(fake));
      await tester.pumpAndSettle();

      expect(find.text('Log in'), findsOneWidget);
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
      expect(find.text('Log in'), findsNothing);
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
      expect(find.textContaining('deactivated'), findsOneWidget);
    });
  });
}
