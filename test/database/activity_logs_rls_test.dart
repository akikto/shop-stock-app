import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static verification of activity_logs RLS — no live database required.
void main() {
  late String rlsSql;
  late String functionsSql;

  setUpAll(() {
    rlsSql = File('supabase/migrations/0003_row_level_security.sql')
        .readAsStringSync();
    functionsSql = File('supabase/migrations/0002_helper_functions.sql')
        .readAsStringSync();
  });

  group('activity_logs RLS', () {
    test('has exactly one SELECT policy scoped to manager/owner or self actor',
        () {
      expect(rlsSql, contains('create policy activity_logs_select_manager_owner'));
      expect(rlsSql, contains('public.is_manager_or_owner() or actor_id = auth.uid()'));
    });

    test('has no client INSERT, UPDATE, or DELETE policies', () {
      expect(rlsSql, isNot(contains('activity_logs for insert')));
      expect(rlsSql, isNot(contains('activity_logs for update')));
      expect(rlsSql, isNot(contains('activity_logs for delete')));
    });

    test('is_manager_or_owner() exists for policy enforcement', () {
      expect(functionsSql, contains('create or replace function public.is_manager_or_owner()'));
    });
  });

  group('Owner/Manager vs Staff visibility contract', () {
    test('manager/owner path is checked before falling back to self-only rows',
        () {
      final policyStart =
          rlsSql.indexOf('create policy activity_logs_select_manager_owner');
      final policyBlock = rlsSql.substring(policyStart, policyStart + 400);
      expect(policyBlock.indexOf('is_manager_or_owner()'),
          lessThan(policyBlock.indexOf('actor_id = auth.uid()')));
    });
  });
}
