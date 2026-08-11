import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// These tests do not connect to a database — Phase 0 has no live
/// Supabase project wired into this repo's test suite. Instead they
/// statically check the migration SQL files for the specific safety
/// guarantees this app depends on, so that an accidental future edit
/// (e.g. someone "temporarily" adding an INSERT policy on `sales` to
/// unblock testing) is caught by CI before it reaches production.
///
/// This complements, but does not replace, manually verifying RLS
/// against a real Supabase project (see README.md).
void main() {
  late String schemaSql;
  late String functionsSql;
  late String rlsSql;

  setUpAll(() {
    schemaSql = File('supabase/migrations/0001_initial_schema.sql').readAsStringSync();
    functionsSql = File('supabase/migrations/0002_helper_functions.sql').readAsStringSync();
    rlsSql = File('supabase/migrations/0003_row_level_security.sql').readAsStringSync();
  });

  group('database safety assumptions', () {
    test('products.current_stock has a database-level non-negative constraint', () {
      final pattern = RegExp(
        r'current_stock\s+numeric\(12,\s*3\)\s+not null default 0 check \(current_stock >= 0\)',
      );
      expect(
        pattern.hasMatch(schemaSql),
        isTrue,
        reason: 'Negative stock must be impossible even if application logic has a bug.',
      );
    });

    test('sales/stock_entries/stock_adjustments have no client INSERT policy in Phase 0', () {
      for (final table in ['sales', 'stock_entries', 'stock_adjustments']) {
        expect(
          rlsSql,
          isNot(contains('create policy ${table}_insert')),
          reason: '$table must only be writable via a future SECURITY DEFINER RPC, '
              'never a direct client insert, in Phase 0.',
        );
      }
    });

    test('activity_logs has no UPDATE or DELETE policy for any role', () {
      expect(rlsSql, isNot(contains('activity_logs for update')));
      expect(rlsSql, isNot(contains('activity_logs for delete')));
    });

    test('activity_logs has no client INSERT policy (written only by future RPC)', () {
      expect(rlsSql, isNot(contains('activity_logs for insert')));
    });

    test('every core table enables row level security', () {
      for (final table in [
        'profiles',
        'products',
        'sales',
        'stock_entries',
        'stock_adjustments',
        'activity_logs',
        'notifications',
      ]) {
        final pattern = RegExp(
          'alter table public\\.$table\\s+enable row level security;',
        );
        expect(
          pattern.hasMatch(rlsSql),
          isTrue,
          reason: '$table must have RLS enabled — default-deny is the whole security model.',
        );
      }
    });

    test('device_txn_id uniqueness exists on transactional tables (idempotent sync)', () {
      final matches = RegExp(r'device_txn_id\s+uuid not null unique').allMatches(schemaSql);
      expect(matches.length, 3,
          reason: 'sales, stock_entries, and stock_adjustments must each guard against '
              'duplicate replay from the offline sync queue.');
    });

    // -------------------------------------------------------------
    // Added after the Phase 0 security review: products was
    // incorrectly given client INSERT/UPDATE policies, which would
    // have let a client write current_stock directly. Fixed to be
    // client-read-only. These tests pin that fix down.
    // -------------------------------------------------------------

    test('products has no client INSERT policy in Phase 0', () {
      expect(
        rlsSql,
        isNot(contains('create policy products_insert')),
        reason: 'Product creation must go through a future RPC, never a direct client insert — '
            'current_stock lives on this table and must never be client-writable.',
      );
    });

    test('products has no client UPDATE policy in Phase 0', () {
      expect(
        rlsSql,
        isNot(contains('create policy products_update')),
        reason: 'Product edits (including current_stock) must go through a future RPC, '
            'never a direct client update.',
      );
    });

    test('products has no DELETE policy for any role', () {
      expect(rlsSql, isNot(contains('products for delete')));
    });

    test('products retains exactly one policy: read-only SELECT for authenticated users', () {
      final productPolicies =
          RegExp(r'create policy products_[a-z_]+').allMatches(rlsSql).map((m) => m.group(0)).toList();
      expect(productPolicies, ['create policy products_select_authenticated']);
    });

    // -------------------------------------------------------------
    // Added after the Phase 0 security review: profiles previously
    // had a single "using (true)" SELECT policy exposing every
    // column — including phone — to every authenticated user. Fixed
    // to a self-row policy plus a manager/owner-only all-rows policy,
    // with a column-limited function for cross-user name lookups.
    // -------------------------------------------------------------

    test('profiles has no blanket "select every row/column" policy for all authenticated users', () {
      expect(
        rlsSql,
        isNot(contains('profiles_select_authenticated')),
        reason: 'A blanket policy would expose every user\'s phone number to every '
            'authenticated user, including plain staff, with no operational need.',
      );
    });

    test('profiles SELECT is split into self-row and manager/owner-only policies', () {
      expect(rlsSql, contains('create policy profiles_select_self'));
      expect(rlsSql, contains('create policy profiles_select_manager_owner'));
    });

    test('list_profiles_public() exists, is SECURITY DEFINER, and excludes phone', () {
      expect(functionsSql, contains('create or replace function public.list_profiles_public()'));
      // The function body must be defined before any "security definer"
      // keyword that could theoretically belong to a different function,
      // so scope the check to the function's own block.
      final functionBlock = functionsSql.substring(
        functionsSql.indexOf('function public.list_profiles_public()'),
      );
      expect(functionBlock, contains('security definer'));
      expect(
        functionBlock.substring(0, functionBlock.indexOf(r'$$;')),
        isNot(contains('phone')),
        reason: 'list_profiles_public() must never return the phone column — that is the '
            'entire point of having it instead of a blanket SELECT policy.',
      );
    });

    test('list_profiles_public() execute privilege is explicitly restricted to authenticated', () {
      expect(functionsSql, contains('revoke all on function public.list_profiles_public() from public;'));
      expect(functionsSql, contains('grant execute on function public.list_profiles_public() to authenticated;'));
    });
  });
}
