import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/features/auth/providers/auth_provider.dart';
import 'package:shop_stock_app/models/profile.dart';
import 'package:shop_stock_app/models/user_role.dart';
import 'package:shop_stock_app/repositories/auth_repository.dart';

import 'fake_auth_repository.dart';

void main() {
  group('auth providers', () {
    test('isAuthenticatedProvider reflects the repository state', () {
      final fake = FakeAuthRepository(signedIn: true);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      addTearDown(fake.dispose);

      expect(container.read(isAuthenticatedProvider), isTrue);
    });

    test('currentProfileProvider surfaces the signed-in user\'s profile',
        () async {
      final profile = Profile(
        id: 'user-1',
        name: 'Owner Name',
        role: UserRole.owner,
        isActive: true,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final fake = FakeAuthRepository(signedIn: true, profile: profile);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      addTearDown(fake.dispose);

      final result = await container.read(currentProfileProvider.future);

      expect(result.role, UserRole.owner);
      expect(result.isActive, isTrue);
    });

    test('currentProfileProvider propagates an error when no profile exists',
        () async {
      final fake = FakeAuthRepository(
        signedIn: true,
        profileError: AuthException(
            'No profile found for this account. Contact the shop owner.'),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      addTearDown(fake.dispose);

      await expectLater(
        container.read(currentProfileProvider.future),
        throwsA(isA<AuthException>()),
      );
    });

    test(
        'a deactivated account is still readable but flagged is_active = false',
        () async {
      final profile = Profile(
        id: 'user-2',
        name: 'Disabled Staff',
        role: UserRole.staff,
        isActive: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final fake = FakeAuthRepository(signedIn: true, profile: profile);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      addTearDown(fake.dispose);

      final result = await container.read(currentProfileProvider.future);

      expect(result.isActive, isFalse,
          reason:
              'App-level UI is responsible for blocking access when isActive is false');
    });
  });
}
