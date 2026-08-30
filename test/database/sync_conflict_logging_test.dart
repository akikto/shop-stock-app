import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migrationSql;

  setUpAll(() {
    migrationSql =
        File('supabase/migrations/0013_sync_conflict_logging.sql').readAsStringSync();
  });

  group('Migration 0013 sync conflict logging', () {
    test('defines log_sync_conflict RPC for authenticated users', () {
      expect(migrationSql,
          contains('create or replace function public.log_sync_conflict'));
      expect(migrationSql, contains('on conflict (device_txn_id) do update'));
      expect(migrationSql,
          contains('grant execute on function public.log_sync_conflict'));
      expect(migrationSql,
          contains('revoke execute on function public.log_sync_conflict'));
    });
  });
}
