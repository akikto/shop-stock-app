import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('resolveNotificationErrorMessage', () {
    test('uses server message when present', () {
      expect(
        resolveNotificationErrorMessage(
          serverMessage: 'denied',
          fallbackMessage: AppStrings.notificationsLoadFailed,
        ),
        'denied',
      );
    });

    test('uses Bengali fallback when server message is empty', () {
      expect(
        resolveNotificationErrorMessage(
          serverMessage: '',
          fallbackMessage: AppStrings.notificationsLoadFailed,
        ),
        AppStrings.notificationsLoadFailed,
      );
    });
  });

  group('SupabaseNotificationRepository markAsRead defense-in-depth', () {
    test('requires authenticated user', () async {
      final client = _MockSupabaseClient();
      final auth = _MockGoTrueClient();
      when(() => client.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(null);

      final repo = SupabaseNotificationRepository(client: client);

      await expectLater(
        repo.markAsRead('n1'),
        throwsA(
          predicate<NotificationException>(
            (e) => e.message == AppStrings.notificationUpdateFailed,
          ),
        ),
      );
    });
  });
}

class _MockGoTrueClient extends Mock implements GoTrueClient {}
