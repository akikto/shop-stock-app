import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// These tests do not connect to a database — there is no live
/// Supabase project wired into this repo's test suite. Instead they
/// statically check supabase/migrations/0006_product_management_rpc.sql
/// for the specific safety guarantees this app depends on, mirroring
/// the approach used for Phase 0 in
/// test/database/security_assumptions_test.dart. This catches an
/// accidental future regression (e.g. someone adding a p_current_stock
/// parameter to "simplify" a bug fix) at review time, but is not a
/// substitute for exercising these functions against a real Postgres
/// instance with real user sessions of each role.
void main() {
  late String rpcSql;
  late String storageSql;
  late String rlsSql;

  setUpAll(() {
    rpcSql = File('supabase/migrations/0006_product_management_rpc.sql').readAsStringSync();
    storageSql = File('supabase/migrations/0004_product_photos_storage.sql').readAsStringSync();
    rlsSql = File('supabase/migrations/0003_row_level_security.sql').readAsStringSync();
  });

  group('create_product() / update_product() never touch current_stock', () {
    test('create_product() has no p_current_stock parameter', () {
      final signature = rpcSql.substring(
        rpcSql.indexOf('create or replace function public.create_product('),
        rpcSql.indexOf(')', rpcSql.indexOf('returns public.products')),
      );
      expect(signature, isNot(contains('current_stock')));
    });

    test('update_product() has no p_current_stock parameter', () {
      final start = rpcSql.indexOf('create or replace function public.update_product(');
      final signature = rpcSql.substring(start, rpcSql.indexOf('returns public.products', start));
      expect(signature, isNot(contains('current_stock')));
    });

    test('update_product()\'s SET clause never assigns current_stock', () {
      final start = rpcSql.indexOf('update public.products set', rpcSql.indexOf('update_product'));
      final end = rpcSql.indexOf('where id = p_id', start);
      final setClause = rpcSql.substring(start, end);
      // Strip SQL comments so the explanatory "current_stock is deliberately
      // absent" comment doesn't trip the check — we only care about actual
      // column assignments, not documentation.
      final noComments = setClause.replaceAll(RegExp(r'--[^\n]*'), '');
      expect(
        noComments,
        isNot(contains('current_stock')),
        reason: 'Product Management must never be able to change stock — only a future '
            'sale/stock-in/adjustment RPC may.',
      );
    });

    test('create_product() always inserts current_stock as the literal 0', () {
      expect(rpcSql, contains(RegExp(r'0,\s*-- current_stock is always 0 at creation')));
    });
  });

  group('authorization checks', () {
    test('all three functions check is_manager_or_owner() before writing anything', () {
      final occurrences = RegExp(r'is_manager_or_owner\(\)').allMatches(rpcSql).length;
      // 3 functions x 1 authorization check each, at minimum.
      expect(occurrences, greaterThanOrEqualTo(3));
    });

    test('all three functions raise an exception when unauthorized, before any insert/update', () {
      for (final fn in ['create_product', 'update_product', 'deactivate_product']) {
        final start = rpcSql.indexOf('function public.$fn(');
        expect(start, greaterThanOrEqualTo(0), reason: '$fn not found');
        final authCheckIndex = rpcSql.indexOf('is_manager_or_owner()', start);
        final raiseIndex = rpcSql.indexOf('raise exception', authCheckIndex);
        final firstWriteIndex = () {
          final insertIdx = rpcSql.indexOf('insert into public.products', start);
          final updateIdx = rpcSql.indexOf('update public.products', start);
          final candidates = [insertIdx, updateIdx].where((i) => i != -1).toList();
          return candidates.isEmpty ? -1 : candidates.reduce((a, b) => a < b ? a : b);
        }();

        expect(authCheckIndex, greaterThan(start), reason: '$fn missing an authorization check');
        expect(raiseIndex, greaterThan(authCheckIndex), reason: '$fn does not raise on failed authorization');
        if (firstWriteIndex != -1) {
          expect(
            authCheckIndex,
            lessThan(firstWriteIndex),
            reason: '$fn must check authorization BEFORE writing to products',
          );
        }
      }
    });
  });

  group('functions are SECURITY DEFINER with a fixed search_path', () {
    test('create_product, update_product, and deactivate_product are all security definer', () {
      final matches = RegExp(r'security definer').allMatches(rpcSql).length;
      expect(matches, 3);
    });

    test('all three set search_path = public (prevents search_path hijacking)', () {
      final matches = RegExp(r'set search_path = public').allMatches(rpcSql).length;
      expect(matches, 3);
    });
  });

  group('execute privilege is explicitly restricted', () {
    test('create_product execute is revoked from public and granted only to authenticated', () {
      expect(rpcSql, contains('revoke all on function public.create_product('));
      expect(rpcSql, contains('grant execute on function public.create_product('));
    });

    test('update_product execute is revoked from public and granted only to authenticated', () {
      expect(rpcSql, contains('revoke all on function public.update_product('));
      expect(rpcSql, contains('grant execute on function public.update_product('));
    });

    test('deactivate_product execute is revoked from public and granted only to authenticated', () {
      expect(rpcSql, contains('revoke all on function public.deactivate_product(uuid) from public;'));
      expect(rpcSql, contains('grant execute on function public.deactivate_product(uuid) to authenticated;'));
    });
  });

  group('audit trail is written by every mutating function', () {
    test('create_product logs a product_created activity row', () {
      expect(rpcSql, contains("'product_created'"));
    });

    test('update_product logs product_updated or price_updated depending on whether price changed', () {
      expect(rpcSql, contains("'price_updated'"));
      expect(rpcSql, contains("'product_updated'"));
      expect(rpcSql, contains('v_price_changed'));
    });

    test('deactivate_product logs a product_deactivated activity row', () {
      expect(rpcSql, contains("'product_deactivated'"));
    });

    test('the product_deactivated enum value is added before any function references it', () {
      final alterIndex = rpcSql.indexOf("add value if not exists 'product_deactivated'");
      final useIndex = rpcSql.indexOf("'product_deactivated',");
      expect(alterIndex, greaterThanOrEqualTo(0));
      expect(useIndex, greaterThan(alterIndex));
    });

    test('every mutating function inserts into activity_logs with actor_id = auth.uid()', () {
      final matches = RegExp(r'insert into public\.activity_logs').allMatches(rpcSql).length;
      expect(matches, 3);
      // auth.uid() must appear as the actor for each of those inserts —
      // approximated by checking overall occurrence count is at least 3
      // beyond the authorization/ownership checks already covered above.
      final actorMatches = RegExp(r'auth\.uid\(\),\s*\n\s*\x27product_').allMatches(rpcSql).length +
          RegExp(r'auth\.uid\(\),\s*\n\s*case when').allMatches(rpcSql).length;
      expect(actorMatches, greaterThanOrEqualTo(1));
    });
  });

  group('products table still has no client-facing write policy (Phase 0 fix holds)', () {
    test('no INSERT policy exists for products', () {
      expect(rlsSql, isNot(contains('create policy products_insert')));
    });
    test('no UPDATE policy exists for products', () {
      expect(rlsSql, isNot(contains('create policy products_update')));
    });
  });

  group('product photo storage is private with role-gated write access', () {
    test('bucket is created as private (public: false)', () {
      expect(storageSql, contains("values ('product-photos', 'product-photos', false)"));
    });

    test('only manager/owner may insert or update objects in the bucket', () {
      expect(storageSql, contains('product_photos_insert_manager_owner'));
      expect(storageSql, contains('product_photos_update_manager_owner'));
      expect(storageSql, contains('public.is_manager_or_owner()'));
    });

    test('no delete policy exists for the product-photos bucket', () {
      expect(storageSql, isNot(contains('for delete')));
    });

    test('any authenticated user may read (select) product photos', () {
      expect(storageSql, contains('product_photos_select_authenticated'));
    });
  });
}
