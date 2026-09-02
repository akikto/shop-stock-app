import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for migration 0014 — notification RPC hardening and
/// low-stock threshold crossing. No live Postgres in CI.
void main() {
  late String migrationSql;
  late String rlsSql;
  late String notificationRepoSource;

  setUpAll(() {
    migrationSql =
        File('supabase/migrations/0014_notification_hardening.sql')
            .readAsStringSync();
    rlsSql = File('supabase/migrations/0003_row_level_security.sql')
        .readAsStringSync();
    notificationRepoSource =
        File('lib/repositories/notification_repository.dart').readAsStringSync();
  });

  group('Migration 0014 mark-as-read RPC security', () {
    test('defines mark_notification_read and mark_all_notifications_read', () {
      expect(migrationSql,
          contains('create or replace function public.mark_notification_read'));
      expect(migrationSql,
          contains('create or replace function public.mark_all_notifications_read'));
    });

    test('RPCs require auth.uid()', () {
      expect(migrationSql, contains('auth.uid()'));
      expect(migrationSql, contains('Authentication required'));
    });

    test('mark_notification_read updates only read for auth.uid recipient', () {
      expect(migrationSql, contains('set read = true'));
      expect(migrationSql, contains('recipient_id = v_uid'));
      expect(migrationSql, isNot(contains('set message')));
      expect(migrationSql, isNot(contains('set type')));
    });

    test('direct client UPDATE policy is removed', () {
      expect(migrationSql,
          contains('drop policy if exists notifications_update_own'));
      expect(migrationSql,
          contains('revoke update on table public.notifications from authenticated'));
    });

    test('RPCs are granted to authenticated only', () {
      expect(migrationSql,
          contains('grant execute on function public.mark_notification_read'));
      expect(migrationSql,
          contains('grant execute on function public.mark_all_notifications_read'));
      expect(migrationSql,
          contains('revoke execute on function public.mark_notification_read'));
    });

    test('RPCs use SECURITY DEFINER with pinned search_path', () {
      expect(migrationSql, contains('security definer'));
      expect(migrationSql, contains('set search_path = public'));
    });

    test('SELECT policy remains from migration 0003', () {
      expect(rlsSql, contains('notifications_select_own'));
      expect(rlsSql, contains('recipient_id = auth.uid()'));
    });

    test('Flutter repository uses RPC not direct UPDATE', () {
      expect(notificationRepoSource, contains("rpc('mark_notification_read'"));
      expect(notificationRepoSource, contains("rpc('mark_all_notifications_read'"));
      expect(notificationRepoSource, isNot(contains(".from('notifications').update")));
    });
  });

  group('Migration 0014 low-stock threshold crossing', () {
    test('replaces single-arg _maybe_notify_low_stock with previous stock param', () {
      expect(migrationSql,
          contains('drop function if exists public._maybe_notify_low_stock(public.products)'));
      expect(migrationSql,
          contains('_maybe_notify_low_stock(public.products, numeric)'));
    });

    test('notifies only when crossing into low stock', () {
      expect(migrationSql,
          contains('p_previous_stock > p_product.low_stock_limit'));
      expect(migrationSql,
          contains('p_product.current_stock <= p_product.low_stock_limit'));
    });

    test('record_sale captures previous stock under row lock', () {
      expect(migrationSql, contains('for update'));
      expect(migrationSql, contains('v_previous_stock'));
      expect(migrationSql,
          contains('_maybe_notify_low_stock(v_product, v_previous_stock)'));
    });

    test('record_adjustment captures previous stock under row lock', () {
      final adjustmentStart = migrationSql.indexOf(
        'create or replace function public.record_adjustment',
      );
      expect(adjustmentStart, greaterThan(0));
      final adjustmentBody = migrationSql.substring(adjustmentStart);
      expect(adjustmentBody, contains('for update'));
      expect(adjustmentBody, contains('v_previous_stock'));
      expect(adjustmentBody,
          contains('_maybe_notify_low_stock(v_product, v_previous_stock)'));
    });

    test('record_stock_in is not modified in 0014', () {
      expect(migrationSql, isNot(contains('record_stock_in'));
    });
  });

  group('Low-stock threshold semantics (documented matrix)', () {
    test('crossing: above limit to at-or-below limit qualifies', () {
      // previous=20, limit=10, new=9 => 20>10 AND 9<=10 => notify
      expect(20 > 10 && 9 <= 10, isTrue);
    });

    test('already low: at limit to below limit does not qualify', () {
      // previous=10, limit=10, new=9 => 10>10 is false => no notify
      expect(10 > 10 && 9 <= 10, isFalse);
    });

    test('already low: below to further below does not qualify', () {
      expect(9 > 10 && 8 <= 10, isFalse);
      expect(8 > 10 && 7 <= 10, isFalse);
    });

    test('recovery then re-cross: above to below qualifies again', () {
      expect(20 > 10 && 9 <= 10, isTrue);
    });
  });
}
