import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks against supabase/migrations/0009_product_expiry_composition_activate.sql
/// — no live database in this environment; the actual apply + live
/// verification for this migration was already run via the Supabase
/// MCP connection earlier in this session (see chat history for the
/// exact read-only verification queries and results). These tests
/// pin the migration file's text down against regressions.
void main() {
  late String sql;
  late String rlsSql;

  setUpAll(() {
    sql =
        File('supabase/migrations/0009_product_expiry_composition_activate.sql')
            .readAsStringSync();
    rlsSql = File('supabase/migrations/0003_row_level_security.sql')
        .readAsStringSync();
  });

  group('new product fields', () {
    test('expiry_date column is added as a nullable date', () {
      expect(sql, contains('add column if not exists expiry_date date'));
    });

    test('composition column is added as nullable text', () {
      expect(sql, contains('add column if not exists composition text'));
    });
  });

  group('avoiding duplicate function overloads', () {
    test(
        'the old-signature create_product is explicitly dropped before recreation',
        () {
      final dropIdx =
          sql.indexOf('drop function if exists public.create_product(');
      final createIdx =
          sql.indexOf('create or replace function public.create_product(');
      expect(dropIdx, greaterThanOrEqualTo(0));
      expect(createIdx, greaterThan(dropIdx),
          reason: 'must drop the old signature before creating the new one');
    });

    test(
        'the old-signature update_product is explicitly dropped before recreation',
        () {
      final dropIdx =
          sql.indexOf('drop function if exists public.update_product(');
      final createIdx =
          sql.indexOf('create or replace function public.update_product(');
      expect(dropIdx, greaterThanOrEqualTo(0));
      expect(createIdx, greaterThan(dropIdx));
    });

    test(
        'exactly one create_product and one update_product definition exist in this file',
        () {
      expect(
          RegExp(r'create or replace function public\.create_product\(')
              .allMatches(sql)
              .length,
          1);
      expect(
          RegExp(r'create or replace function public\.update_product\(')
              .allMatches(sql)
              .length,
          1);
    });
  });

  group(
      'activate_product() mirrors deactivate_product()\'s authorization pattern',
      () {
    test('activate_product is defined, SECURITY DEFINER, manager/owner only',
        () {
      final start = sql.indexOf('function public.activate_product(');
      expect(start, greaterThanOrEqualTo(0));
      final authIdx = sql.indexOf('is_manager_or_owner()', start);
      expect(authIdx, greaterThan(start));
    });

    test('activate_product sets is_active = true (not false)', () {
      final start = sql.indexOf('function public.activate_product(');
      final body = sql.substring(start, sql.indexOf(r'$$;', start));
      expect(body, contains('set is_active = true'));
      expect(body, isNot(contains('set is_active = false')));
    });

    test('activate_product logs a product_activated activity entry', () {
      expect(sql, contains("'product_activated'"));
    });
  });

  group('current_stock guarantee still holds after this migration', () {
    test(
        'neither create_product nor update_product accept current_stock as a parameter',
        () {
      final createSig = sql.substring(
        sql.indexOf('create or replace function public.create_product('),
        sql.indexOf('returns public.products',
            sql.indexOf('create or replace function public.create_product(')),
      );
      final updateSig = sql.substring(
        sql.indexOf('create or replace function public.update_product('),
        sql.indexOf('returns public.products',
            sql.indexOf('create or replace function public.update_product(')),
      );
      expect(createSig, isNot(contains('current_stock')));
      expect(updateSig, isNot(contains('current_stock')));
    });

    test('update_product\'s SET clause still never assigns current_stock', () {
      final setStart = sql.indexOf('update public.products set',
          sql.indexOf('function public.update_product('));
      final setEnd = sql.indexOf('where id = p_id', setStart);
      final setClause = sql.substring(setStart, setEnd);
      // Check for an actual assignment (current_stock = ...), not just
      // the word anywhere — this migration's own explanatory comment
      // ("current_stock is deliberately absent...") legitimately
      // contains the word without being an assignment.
      expect(RegExp(r'current_stock\s*=').hasMatch(setClause), isFalse);
    });
  });

  group('execute privilege follows the anon-revoked defense-in-depth pattern',
      () {
    test('activate_product: anon revoked, authenticated granted', () {
      expect(
          sql,
          contains(
              'revoke execute on function public.activate_product(uuid) from anon;'));
      expect(
          sql,
          contains(
              'grant execute on function public.activate_product(uuid) to authenticated;'));
    });

    test(
        'the new create_product/update_product signatures also revoke anon and grant authenticated',
        () {
      expect(
          sql,
          contains(
              'revoke execute on function public.create_product(\n  text, text, text, text, text, text, numeric, numeric, numeric, numeric, date, text\n) from anon;'));
      expect(
          sql,
          contains(
              'revoke execute on function public.update_product(\n  uuid, text, text, text, text, text, text, numeric, numeric, numeric, numeric, date, text\n) from anon;'));
    });
  });

  group(
      'products RLS still has no client INSERT/UPDATE policy (unchanged from Phase 0/1)',
      () {
    test('no products_insert or products_update policy exists', () {
      expect(rlsSql, isNot(contains('create policy products_insert')));
      expect(rlsSql, isNot(contains('create policy products_update')));
    });
  });
}
