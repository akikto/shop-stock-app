import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/features/auth/providers/auth_provider.dart';
import 'package:shop_stock_app/features/home/providers/fcm_providers.dart';
import 'package:shop_stock_app/models/profile.dart';
import 'package:shop_stock_app/models/user_role.dart';
import 'package:shop_stock_app/services/fcm_service.dart';

class _RecordingFcmService extends FcmService {
  _RecordingFcmService() : super(client: null);

  int registerCalls = 0;
  int configureCalls = 0;

  @override
  Future<void> registerTokenIfAvailable() async {
    registerCalls++;
  }

  @override
  Future<void> configureMessageHandlers() async {
    configureCalls++;
  }
}

Profile _profile({bool active = true}) => Profile(
      id: 'p1',
      name: 'Karim',
      role: UserRole.manager,
      isActive: active,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  group('fcmRegistrationProvider', () {
    test('does nothing while profile is still loading', () {
      final recording = _RecordingFcmService();
      final container = ProviderContainer(
        overrides: [
          fcmServiceProvider.overrideWithValue(recording),
        ],
      );
      addTearDown(container.dispose);

      container.read(fcmRegistrationProvider);
      expect(recording.registerCalls, 0);
    });

    test('does nothing when profile is inactive', () async {
      final recording = _RecordingFcmService();
      final container = ProviderContainer(
        overrides: [
          fcmServiceProvider.overrideWithValue(recording),
          currentProfileProvider.overrideWith((ref) async => _profile(active: false)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(currentProfileProvider.future);
      container.read(fcmRegistrationProvider);

      expect(recording.registerCalls, 0);
    });

    test('registers token when profile is active', () async {
      final recording = _RecordingFcmService();
      final container = ProviderContainer(
        overrides: [
          fcmServiceProvider.overrideWithValue(recording),
          currentProfileProvider.overrideWith((ref) async => _profile()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(currentProfileProvider.future);
      container.read(fcmRegistrationProvider);

      expect(recording.registerCalls, 1);
      expect(recording.configureCalls, 1);
    });
  });
}
