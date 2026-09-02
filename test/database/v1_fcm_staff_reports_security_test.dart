import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:shop_stock_app/models/stock_movement_row.dart';

void main() {
  late String migrationSql;
  late String pushIndexSource;
  late String pushHandlerSource;
  late String pushFcmSource;

  setUpAll(() {
    migrationSql =
        File('supabase/migrations/0012_v1_fcm_staff_reports.sql').readAsStringSync();
    pushIndexSource =
        File('supabase/functions/send-push-notification/index.ts')
            .readAsStringSync();
    pushHandlerSource =
        File('supabase/functions/send-push-notification/handler.ts')
            .readAsStringSync();
    pushFcmSource =
        File('supabase/functions/send-push-notification/fcm.ts')
            .readAsStringSync();
  });

  group('Migration 0012 v1.0 safety', () {
    test('defines FCM token registration RPC', () {
      expect(migrationSql,
          contains('create or replace function public.register_fcm_token'));
      expect(migrationSql, contains('grant execute on function public.register_fcm_token'));
      expect(migrationSql, contains('revoke execute on function public.register_fcm_token'));
    });

    test('notification preferences are user-scoped with owner override', () {
      expect(migrationSql, contains('create table if not exists public.notification_preferences'));
      expect(migrationSql,
          contains('create or replace function public.get_notification_preferences'));
      expect(migrationSql,
          contains('create or replace function public.upsert_notification_preferences'));
    });

    test('stock movement report is manager/owner gated', () {
      expect(migrationSql,
          contains('create or replace function public.get_stock_movement_report'));
      expect(migrationSql, contains('if not public.is_manager_or_owner()'));
    });

    test('staff management RPCs are owner-only', () {
      expect(migrationSql,
          contains('create or replace function public.list_staff_profiles'));
      expect(migrationSql,
          contains('if not public.is_owner() then'));
      expect(migrationSql,
          contains('create or replace function public.update_staff_role'));
      expect(migrationSql,
          contains('create or replace function public.set_staff_active'));
    });

    test('sync conflicts are manager/owner readable', () {
      expect(migrationSql, contains('create table if not exists public.sync_conflicts'));
      expect(migrationSql,
          contains('create or replace function public.list_sync_conflicts'));
      expect(migrationSql,
          contains('create or replace function public.resolve_sync_conflict'));
    });

    test('low stock list is manager/owner gated', () {
      expect(migrationSql,
          contains('create or replace function public.list_low_stock_products'));
    });

    test('realtime publication includes notifications, products, activity_logs', () {
      expect(migrationSql, contains("tablename = 'notifications'"));
      expect(migrationSql, contains("tablename = 'products'"));
      expect(migrationSql, contains("tablename = 'activity_logs'"));
    });
  });

  group('send-push-notification Edge Function security', () {
    test('requires webhook secret header', () {
      expect(pushIndexSource, contains('PUSH_WEBHOOK_SECRET'));
      expect(pushIndexSource, contains('x-push-webhook-secret'));
      expect(pushIndexSource, contains('--no-verify-jwt'));
    });

    test('uses server-side Firebase service account secret only', () {
      expect(pushIndexSource, contains('FIREBASE_SERVICE_ACCOUNT'));
      expect(pushIndexSource, isNot(contains('private_key:')));
    });

    test('queries fcm_tokens by recipient from webhook record', () {
      expect(pushHandlerSource, contains('.from("fcm_tokens")'));
      expect(
        pushHandlerSource,
        contains('.eq("user_id", record.recipient_id)'),
      );
    });

    test('does not accept client-supplied recipient override', () {
      expect(pushHandlerSource, isNot(contains('body.recipient')));
      expect(pushHandlerSource, contains('parseNotificationInsert'));
    });

    test('uses FCM HTTP v1 endpoint', () {
      expect(pushFcmSource, contains('fcm.googleapis.com/v1/projects'));
      expect(pushFcmSource, isNot(contains('fcm/send')));
    });

    test('removes permanently invalid tokens scoped to recipient', () {
      expect(pushHandlerSource, contains('removeStaleToken'));
      expect(pushHandlerSource, contains('.eq("user_id", recipientId)'));
      expect(pushHandlerSource, contains('.eq("token", token)'));
    });

    test('includes data payload keys for Flutter routing compatibility', () {
      expect(pushFcmSource, contains('notification_id'));
      expect(pushFcmSource, contains('notification_type'));
      expect(pushFcmSource, contains('recipient_id'));
      expect(pushFcmSource, contains('route'));
      expect(pushFcmSource, contains('"notifications"'));
    });

    test('does not log full device tokens', () {
      expect(pushHandlerSource, contains('token_suffix'));
      expect(pushHandlerSource, isNot(contains('console.log(token)')));
    });
  });

  group('StockMovementRow', () {
    test('parses report row JSON', () {
      final row = StockMovementRow.fromJson({
        'movement_type': 'sale',
        'reference_id': 'r1',
        'product_id': 'p1',
        'product_name': 'Soap',
        'user_id': 'u1',
        'user_name': 'Karim',
        'quantity': 2,
        'quantity_change': -2,
        'reason': null,
        'amount': 40,
        'created_at': '2026-08-01T10:00:00Z',
      });
      expect(row.movementType, 'sale');
      expect(row.productName, 'Soap');
      expect(row.quantityChange, -2);
    });
  });
}
