import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks against supabase/migrations/0008_sale_stock_rpc.sql —
/// no live database available in this environment. Mirrors the
/// approach used for migration 0006 in
/// test/database/product_rpc_security_test.dart.
void main() {
  late String sql;
  late String rlsSql;

  setUpAll(() {
    sql = File('supabase/migrations/0008_sale_stock_rpc.sql').readAsStringSync();
    rlsSql = File('supabase/migrations/0003_row_level_security.sql').readAsStringSync();
  });

  group('all three functions exist and are SECURITY DEFINER with pinned search_path', () {
    test('record_sale, record_stock_in, record_adjustment are all defined', () {
      expect(sql, contains('create or replace function public.record_sale('));
      expect(sql, contains('create or replace function public.record_stock_in('));
      expect(sql, contains('create or replace function public.record_adjustment('));
    });

    test('all three are SECURITY DEFINER', () {
      expect(RegExp(r'security definer').allMatches(sql).length, 3);
    });

    test('all three pin search_path to public', () {
      expect(RegExp(r'set search_path = public').allMatches(sql).length, 3);
    });
  });

  group('authorization matches intended role design', () {
    test('record_adjustment requires is_manager_or_owner() — staff cannot adjust stock', () {
      final start = sql.indexOf('function public.record_adjustment(');
      final authIdx = sql.indexOf('is_manager_or_owner()', start);
      expect(authIdx, greaterThan(start), reason: 'record_adjustment must check manager/owner role');
    });

    test('record_sale and record_stock_in do NOT require manager/owner (any active staff may use them)', () {
      final saleStart = sql.indexOf('function public.record_sale(');
      final saleEnd = sql.indexOf('function public.record_stock_in(');
      final saleBody = sql.substring(saleStart, saleEnd);
      expect(saleBody, isNot(contains('is_manager_or_owner')));

      final stockInStart = saleEnd;
      final stockInEnd = sql.indexOf('function public.record_adjustment(');
      final stockInBody = sql.substring(stockInStart, stockInEnd);
      expect(stockInBody, isNot(contains('is_manager_or_owner')));
    });

    test('record_sale and record_stock_in still require an active profile', () {
      final saleStart = sql.indexOf('function public.record_sale(');
      final saleEnd = sql.indexOf('function public.record_stock_in(');
      expect(sql.substring(saleStart, saleEnd), contains('is_active'));
    });

    test('all three require auth.uid() to be non-null before doing anything else', () {
      final occurrences = RegExp(r'auth\.uid\(\) is null').allMatches(sql).length;
      expect(occurrences, 3);
    });
  });

  group('negative stock is structurally impossible', () {
    test('record_sale\'s stock decrement re-checks sufficient stock in the same atomic UPDATE', () {
      expect(sql, contains('current_stock = current_stock - p_quantity'));
      expect(sql, contains('and current_stock >= p_quantity'));
    });

    test('record_adjustment\'s UPDATE guards the resulting stock against going negative', () {
      expect(sql, contains('current_stock = current_stock + p_quantity_change'));
      expect(sql, contains('and current_stock + p_quantity_change >= 0'));
    });

    test('insufficient stock raises a distinct, user-readable error', () {
      expect(sql, contains("'Insufficient stock.'"));
    });

    test('a would-go-negative adjustment raises a distinct, user-readable error', () {
      expect(sql, contains("'Adjustment would result in negative stock.'"));
    });
  });

  group('idempotency / offline-sync readiness', () {
    test('every function accepts and requires a device_txn_id', () {
      final occurrences = RegExp(r'p_device_txn_id').allMatches(sql).length;
      expect(occurrences, greaterThanOrEqualTo(9));
    });
  });

  group('execute privilege follows the anon-revoked defense-in-depth pattern', () {
    test('anon execute is explicitly revoked for all three functions', () {
      expect(
          RegExp(r'revoke execute on function public\.record_(sale|stock_in|adjustment)\([^)]*\) from anon;')
              .allMatches(sql)
              .length,
          3);
    });

    test('authenticated execute is explicitly granted for all three functions', () {
      expect(
          RegExp(r'grant execute on function public\.record_(sale|stock_in|adjustment)\([^)]*\) to authenticated;')
              .allMatches(sql)
              .length,
          3);
    });
  });

  group('mutating ledger tables still have no client INSERT policy (Phase 0/1 pattern preserved)', () {
    test('sales/stock_entries/stock_adjustments have no INSERT policy anywhere', () {
      for (final table in ['sales', 'stock_entries', 'stock_adjustments']) {
        expect(rlsSql, isNot(contains('create policy ${table}_insert')));
      }
    });

    test('products still has no UPDATE policy (stock changes only via these RPCs)', () {
      expect(rlsSql, isNot(contains('create policy products_update')));
    });
  });

  group('activity_logs entries are written for every mutating action', () {
    test('record_sale logs a sale entry', () => expect(sql, contains("'sale',")));
    test('record_stock_in logs a stock_in entry', () => expect(sql, contains("'stock_in',")));
    test('record_adjustment logs a stock_adjustment entry', () => expect(sql, contains("'stock_adjustment',")));
  });
}
