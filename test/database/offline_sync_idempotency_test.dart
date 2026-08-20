import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for migration 0011 — idempotent offline sync replay.
void main() {
  late String sql;

  setUpAll(() {
    sql = File('supabase/migrations/0011_offline_sync_idempotency.sql')
        .readAsStringSync();
  });

  group('Phase 5 idempotent transaction RPCs', () {
    test('all three functions are redefined', () {
      expect(sql, contains('create or replace function public.record_sale('));
      expect(
          sql, contains('create or replace function public.record_stock_in('));
      expect(sql,
          contains('create or replace function public.record_adjustment('));
    });

    test('all three remain SECURITY DEFINER with pinned search_path', () {
      expect(RegExp(r'security definer').allMatches(sql).length, 3);
      expect(RegExp(r'set search_path = public').allMatches(sql).length, 3);
    });

    test('record_sale returns existing row when device_txn_id already exists',
        () {
      final start = sql.indexOf('function public.record_sale(');
      final end = sql.indexOf('function public.record_stock_in(');
      final body = sql.substring(start, end);
      expect(body,
          contains('from public.sales where device_txn_id = p_device_txn_id'));
      expect(body, contains('if found then'));
      expect(body, contains('return v_sale'));
      expect(
        body.indexOf('from public.sales where device_txn_id'),
        lessThan(body.indexOf('current_stock = current_stock - p_quantity')),
        reason: 'must check ledger before stock mutation',
      );
    });

    test(
        'record_stock_in returns existing row when device_txn_id already exists',
        () {
      final start = sql.indexOf('function public.record_stock_in(');
      final end = sql.indexOf('function public.record_adjustment(');
      final body = sql.substring(start, end);
      expect(
          body,
          contains(
              'from public.stock_entries where device_txn_id = p_device_txn_id'));
      expect(
        body.indexOf('from public.stock_entries where device_txn_id'),
        lessThan(body.indexOf('current_stock = current_stock + p_quantity')),
      );
    });

    test(
        'record_adjustment returns existing row when device_txn_id already exists',
        () {
      final start = sql.indexOf('function public.record_adjustment(');
      final body = sql.substring(start);
      expect(
          body,
          contains(
              'from public.stock_adjustments where device_txn_id = p_device_txn_id'));
      expect(
        body.indexOf('from public.stock_adjustments where device_txn_id'),
        lessThan(
            body.indexOf('current_stock = current_stock + p_quantity_change')),
      );
    });

    test('advisory lock prevents concurrent duplicate replay races', () {
      expect(
          RegExp(r'pg_advisory_xact_lock\(hashtext\(p_device_txn_id::text\)\)')
              .allMatches(sql)
              .length,
          3);
    });

    test('unique_violation on insert is handled for all three functions', () {
      expect(RegExp(r'when unique_violation then').allMatches(sql).length, 3);
    });

    test('record_adjustment still requires manager or owner', () {
      final start = sql.indexOf('function public.record_adjustment(');
      final body = sql.substring(start);
      expect(body, contains('is_manager_or_owner()'));
    });

    test('no new Supabase tables or client INSERT policies are introduced', () {
      expect(sql.toLowerCase(), isNot(contains('create table')));
      expect(sql, isNot(contains('create policy')));
    });
  });
}
