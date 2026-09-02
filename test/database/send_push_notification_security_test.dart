import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks against supabase/functions/send-push-notification/ — no live
/// Firebase or Supabase credentials in CI. Mirrors migration SQL security tests.
void main() {
  late String indexSource;
  late String handlerSource;
  late String fcmSource;

  setUpAll(() {
    indexSource = File('supabase/functions/send-push-notification/index.ts')
        .readAsStringSync();
    handlerSource = File('supabase/functions/send-push-notification/handler.ts')
        .readAsStringSync();
    fcmSource = File('supabase/functions/send-push-notification/fcm.ts')
        .readAsStringSync();
  });

  group('send-push-notification Edge Function security', () {
    test('requires webhook secret header', () {
      expect(indexSource, contains('PUSH_WEBHOOK_SECRET'));
      expect(indexSource, contains('x-push-webhook-secret'));
      expect(indexSource, contains('--no-verify-jwt'));
    });

    test('uses server-side Firebase service account secret only', () {
      expect(indexSource, contains('FIREBASE_SERVICE_ACCOUNT'));
      expect(indexSource, isNot(contains('private_key:')));
    });

    test('queries fcm_tokens by recipient from webhook record', () {
      expect(handlerSource, contains('.from("fcm_tokens")'));
      expect(handlerSource, contains('.eq("user_id", record.recipient_id)'));
    });

    test('does not accept client-supplied recipient override', () {
      expect(handlerSource, isNot(contains('body.recipient')));
      expect(handlerSource, contains('parseNotificationInsert'));
    });

    test('uses FCM HTTP v1 endpoint', () {
      expect(fcmSource, contains('fcm.googleapis.com/v1/projects'));
      expect(fcmSource, isNot(contains('fcm/send')));
    });

    test('removes permanently invalid tokens scoped to recipient', () {
      expect(handlerSource, contains('removeStaleToken'));
      expect(handlerSource, contains('.eq("user_id", recipientId)'));
      expect(handlerSource, contains('.eq("token", token)'));
    });

    test('includes data payload keys for Flutter routing compatibility', () {
      expect(fcmSource, contains('notification_id'));
      expect(fcmSource, contains('notification_type'));
      expect(fcmSource, contains('recipient_id'));
      expect(fcmSource, contains('route'));
      expect(fcmSource, contains('"notifications"'));
    });

    test('does not log full device tokens', () {
      expect(handlerSource, contains('token_suffix'));
      expect(handlerSource, isNot(contains('console.log(token)')));
    });

    test('verifies notification row before push delivery', () {
      expect(handlerSource, contains('verifyNotificationExists'));
    });

    test('checks notification preferences before FCM send', () {
      expect(handlerSource, contains('loadNotificationPreferences'));
      expect(handlerSource, contains('preferences_disabled'));
    });
  });
}
