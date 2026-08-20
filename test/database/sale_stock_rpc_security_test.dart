import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static security checks for migration 0007 — mirrors the approach
/// used in product_rpc_security_test.dart for migration 0006. These
/// tests do NOT connect to a database; they verify the SQL source
/// contains the safety guarantees the app depends on.
void main() {
  late String rpcSql;
  late String rlsSql;

  setUpAll(() {
    rpcSql = File('supabase/migrations/0007_sale_stock_rpc.sql').readAsStringSync();
    rlsSql = File('supabase/migrations/0003_row_level_security.sql').readAsStringSync();
  });

  group('no RPC function accepts current_stock as a parameter', () {
    test('record_sale() has no p_current_stock parameter', () {
      final start = rpcSql.indexOf('function public.record_sale(');
      final signature = rpcSql.substring(start, rpcSql.indexOf('returns public.sales', start));
      expect(signature, isNot(contains('current_stock')));
    });

    test('record_stock_in() has no p_current_stock parameter', () {
      final start = rpcSql.indexOf('function public.record_stock_in(');
      final signature = rpcSql.substring(start, rpcSql.indexOf('returns public.stock_entries', start));
      expect(signature, isNot(contains('current_stock')));
    });

    test('record_adjustment() has no p_current_stock parameter', () {
      final start = rpcSql.indexOf('function public.record_adjustment(');
      final signature = rpcSql.substring(start, rpcSql.indexOf('returns public.stock_adjustments', start));
      expect(signature, isNot(contains('current_stock')));
    });
  });

  group('all three functions are SECURITY DEFINER with fixed search_path', () {
    test('all three are security definer', () {
      final matches = RegExp(r'security definer').allMatches(rpcSql).length;
      expect(matches, 3);
    });

    test('all three set search_path = public', () {
      final matches = RegExp(r'set search_path = public').allMatches(rpcSql).length;
      expect(matches, 3);
    });
  });

  group('authorization checks', () {
    test('record_adjustment checks is_manager_or_owner() before writing', () {
      final start = rpcSql.indexOf('function public.record_adjustment(');
      final authCheck = rpcSql.indexOf('is_manager_or_owner()', start);
      final raiseIndex = rpcSql.indexOf('raise exception', authCheck);
      final firstWrite = rpcSql.indexOf('update public.products', start);

      expect(authCheck, greaterThan(start));
      expect(raiseIndex, greaterThan(authCheck));
      expect(authCheck, lessThan(firstWrite));
    });

    test('record_sale and record_stock_in require auth.uid() to be non-null', () {
      expect(rpcSql, contains(RegExp(r"raise exception 'Authentication required\.' using errcode = '28000'")));
    });

    test('all three functions check auth.uid() is not null', () {
      final matches = RegExp(r"auth\.uid\(\) is null").allMatches(rpcSql).length;
      expect(matches, 3);
    });
  });

  group('atomic stock operations prevent negative stock', () {
    test('record_sale uses WHERE current_stock >= p_quantity', () {
      expect(rpcSql, contains('current_stock >= p_quantity'));
    });

    test('record_adjustment uses WHERE current_stock + p_quantity_change >= 0', () {
      expect(rpcSql, contains('current_stock + p_quantity_change >= 0'));
    });

    test('record_sale checks row_count after update and raises on insufficient stock', () {
      expect(rpcSql, contains('get diagnostics v_updated = row_count'));
      expect(rpcSql, contains('Insufficient stock'));
    });

    test('record_adjustment checks row_count and raises on negative result', () {
      expect(rpcSql, contains('Adjustment would make stock negative'));
    });
  });

  group('execute privilege is restricted', () {
    test('record_sale is revoked from public and granted to authenticated', () {
      expect(rpcSql, contains('revoke all on function public.record_sale(uuid, numeric, uuid) from public'));
      expect(rpcSql, contains('grant execute on function public.record_sale(uuid, numeric, uuid) to authenticated'));
    });

    test('record_stock_in is revoked from public and granted to authenticated', () {
      expect(rpcSql, contains('revoke all on function public.record_stock_in(uuid, numeric, uuid) from public'));
      expect(rpcSql, contains('grant execute on function public.record_stock_in(uuid, numeric, uuid) to authenticated'));
    });

    test('record_adjustment is revoked from public and granted to authenticated', () {
      expect(rpcSql, contains('revoke all on function public.record_adjustment(uuid, numeric, text, uuid) from public'));
      expect(rpcSql, contains('grant execute on function public.record_adjustment(uuid, numeric, text, uuid) to authenticated'));
    });
  });

  group('activity logs are written for every operation', () {
    test('record_sale logs a sale activity row', () {
      expect(rpcSql, contains("'sale'"));
    });

    test('record_stock_in logs a stock_in activity row', () {
      expect(rpcSql, contains("'stock_in'"));
    });

    test('record_adjustment logs a stock_adjustment activity row', () {
      expect(rpcSql, contains("'stock_adjustment'"));
    });

    test('all three insert into activity_logs', () {
      final matches = RegExp(r'insert into public\.activity_logs').allMatches(rpcSql).length;
      expect(matches, 3);
    });
  });

  group('RLS still has no client INSERT/UPDATE on sales/stock tables', () {
    test('no INSERT policy exists for sales', () {
      expect(rlsSql, isNot(contains('create policy sales_insert')));
    });
    test('no INSERT policy exists for stock_entries', () {
      expect(rlsSql, isNot(contains('create policy stock_entries_insert')));
    });
    test('no INSERT policy exists for stock_adjustments', () {
      expect(rlsSql, isNot(contains('create policy stock_adjustments_insert')));
    });
    test('no UPDATE policy exists for products (Phase 0 fix still holds)', () {
      expect(rlsSql, isNot(contains('create policy products_update')));
    });
  });

  group('input validation', () {
    test('record_sale rejects quantity <= 0', () {
      expect(rpcSql, contains('p_quantity <= 0'));
    });
    test('record_stock_in rejects quantity <= 0', () {
      expect(rpcSql, contains('p_quantity <= 0'));
    });
    test('record_adjustment rejects quantity_change = 0', () {
      expect(rpcSql, contains('p_quantity_change = 0'));
    });
    test('record_adjustment requires non-empty reason', () {
      expect(rpcSql, contains("btrim(p_reason) = ''"));
    });
  });
}
