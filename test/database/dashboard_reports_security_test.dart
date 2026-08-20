import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migrationSql;

  setUpAll(() {
    migrationSql =
        File('supabase/migrations/0010_dashboard_reports_notifications.sql')
            .readAsStringSync();
  });

  group('Phase 4 migration safety', () {
    test('defines dashboard and report RPCs with manager/owner gates', () {
      expect(migrationSql,
          contains('create or replace function public.get_dashboard_stats'));
      expect(migrationSql,
          contains('create or replace function public.get_staff_sales_report'));
      expect(
          migrationSql,
          contains(
              'create or replace function public.get_product_sales_report'));
      expect(migrationSql, contains('if not public.is_manager_or_owner()'));
    });

    test('notifications are created server-side only', () {
      expect(
          migrationSql,
          contains(
              'create or replace function public._notify_managers_owners'));
      expect(migrationSql, contains("insert into public.notifications"));
      expect(migrationSql, contains('perform public._maybe_notify_low_stock'));
    });

    test('report RPCs are granted to authenticated only', () {
      expect(migrationSql,
          contains('grant execute on function public.get_dashboard_stats'));
      expect(migrationSql,
          contains('revoke execute on function public.get_staff_sales_report'));
    });
  });
}
