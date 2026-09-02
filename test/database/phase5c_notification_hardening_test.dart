import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phase 5C static security and behavior audits — no live Supabase/Firebase.
void main() {
  late String rlsSql;
  late String migration0010Sql;
  late String migration0012Sql;
  late String notificationRepoSource;
  late String handlerSource;
  late String preferencesSource;
  late String fcmServiceSource;

  setUpAll(() {
    rlsSql = File('supabase/migrations/0003_row_level_security.sql')
        .readAsStringSync();
    migration0010Sql =
        File('supabase/migrations/0010_dashboard_reports_notifications.sql')
            .readAsStringSync();
    migration0012Sql =
        File('supabase/migrations/0012_v1_fcm_staff_reports.sql')
            .readAsStringSync();
    notificationRepoSource =
        File('lib/repositories/notification_repository.dart').readAsStringSync();
    handlerSource =
        File('supabase/functions/send-push-notification/handler.ts')
            .readAsStringSync();
    preferencesSource =
        File('supabase/functions/send-push-notification/preferences.ts')
            .readAsStringSync();
    fcmServiceSource =
        File('lib/services/fcm_service.dart').readAsStringSync();
  });

  group('Phase 5C notification UPDATE security', () {
    test('RLS allows recipient-scoped UPDATE only', () {
      expect(rlsSql, contains('notifications_update_own'));
      expect(rlsSql, contains('recipient_id = auth.uid()'));
    });

    test('RLS does not column-restrict UPDATE (migration required for hardening)', () {
      expect(rlsSql, isNot(contains('mark_notification_read')));
      expect(rlsSql, isNot(contains('only column read')));
    });

    test('Flutter markAsRead updates read field only', () {
      expect(notificationRepoSource, contains(".update({'read': true})"));
      expect(notificationRepoSource, isNot(contains("'message':")));
      expect(notificationRepoSource, isNot(contains("'type':")));
      expect(notificationRepoSource, isNot(contains("'recipient_id':")));
    });

    test('notifications have no client INSERT policy', () {
      expect(rlsSql, contains('No client INSERT policy'));
    });
  });

  group('Phase 5C low-stock deduplication audit', () {
    test('_maybe_notify_low_stock exists and checks threshold', () {
      expect(migration0010Sql, contains('_maybe_notify_low_stock'));
      expect(
        migration0010Sql,
        contains('p_product.current_stock <= p_product.low_stock_limit'),
      );
    });

    test('low-stock has no threshold-crossing guard (migration required)', () {
      expect(migration0010Sql, isNot(contains('p_previous_stock')));
    });

    test('low-stock fires after sale and adjustment only', () {
      expect(migration0010Sql, contains('_maybe_notify_low_stock(v_product)'));
    });
  });

  group('Phase 5C notification preferences', () {
    test('inbox creation respects preferences in _notify_managers_owners', () {
      expect(migration0012Sql, contains('notification_preferences'));
      expect(migration0012Sql, contains('coalesce(np.notify_sale, true)'));
      expect(migration0012Sql, contains('coalesce(np.notify_low_stock, true)'));
    });

    test('edge function checks preferences before FCM send', () {
      expect(handlerSource, contains('loadNotificationPreferences'));
      expect(handlerSource, contains('isPushEnabledForType'));
      expect(handlerSource, contains('preferences_disabled'));
    });

    test('preference defaults match SQL coalesce(true) semantics', () {
      expect(preferencesSource, contains('value !== false'));
    });
  });

  group('Phase 5C inbox vs push separation', () {
    test('Flutter does not invoke send-push-notification', () {
      expect(notificationRepoSource, isNot(contains('send-push-notification')));
      expect(notificationRepoSource, isNot(contains('functions.invoke'));
    });

    test('push layer verifies notification row exists', () {
      expect(handlerSource, contains('verifyNotificationExists'));
    });

    test('push skip does not imply inbox deletion', () {
      expect(handlerSource, isNot(contains('.from("notifications").delete'));
    });
  });

  group('Phase 5C FCM token hygiene', () {
    test('register_fcm_token upserts per user and token', () {
      expect(migration0012Sql, contains('register_fcm_token'));
      expect(migration0012Sql, contains('on conflict (user_id, token)'));
    });

    test('fcm_tokens RLS scopes to auth.uid()', () {
      expect(migration0012Sql, contains('fcm_tokens_select_own'));
      expect(migration0012Sql, contains('user_id = auth.uid()'));
      expect(migration0012Sql, contains('fcm_tokens_delete_own'));
    });

    test('stale token cleanup is scoped to user_id and token pair', () {
      expect(handlerSource, contains('.eq("user_id", recipientId)'));
      expect(handlerSource, contains('.eq("token", token)'));
    });

    test('logout unregisters current device token', () {
      expect(fcmServiceSource, contains('unregisterTokenIfAvailable'));
      expect(fcmServiceSource, contains(".eq('user_id', userId)"));
      expect(fcmServiceSource, contains(".eq('token', token)"));
    });
  });

  group('Phase 5C FCM failure handling', () {
    test('temporary failures map to HTTP 503 for webhook retry', () {
      expect(handlerSource, contains('Temporary FCM delivery failure'));
      expect(handlerSource, contains('503'));
    });

    test('no tokens is a safe skip not an error', () {
      expect(handlerSource, contains('no_tokens'));
    });
  });

  group('Phase 5C webhook idempotency audit', () {
    test('no push deduplication table or column exists yet', () {
      expect(migration0012Sql, isNot(contains('push_sent_at')));
      expect(handlerSource, isNot(contains('dedup')));
    });
  });

  group('Phase 5C sign-out token hygiene', () {
    test('deactivated account sign-out unregisters FCM token', () {
      final routerSource =
          File('lib/core/routing/app_router.dart').readAsStringSync();
      expect(routerSource, contains('unregisterTokenIfAvailable'));
      expect(routerSource, contains('accountDeactivated'));
    });
  });
}
