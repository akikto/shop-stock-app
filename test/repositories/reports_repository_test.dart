import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/models/dashboard_stats.dart';
import 'package:shop_stock_app/models/product_sales_row.dart';
import 'package:shop_stock_app/models/staff_sales_row.dart';
import 'package:shop_stock_app/models/stock_movement_row.dart';
import 'package:shop_stock_app/repositories/reports_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ReportsMockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late _ReportsMockSupabaseClient client;
  late SupabaseReportsRepository repo;

  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 1, 2);

  setUp(() {
    client = _ReportsMockSupabaseClient();
    repo = SupabaseReportsRepository(client: client);
  });

  group('SupabaseReportsRepository', () {
    test('fetchDashboardStats parses RPC JSON', () async {
      when(() => client.rpc('get_dashboard_stats', params: any(named: 'params')))
          .thenAnswer(
        (_) async => {
          'role_scope': 'shop',
          'sale_count': 3,
          'total_sales_amount': 300,
          'stock_in_count': 1,
          'adjustment_count': 0,
          'low_stock_count': 2,
        },
      );

      final stats = await repo.fetchDashboardStats(from: from, to: to);

      expect(stats, isA<DashboardStats>());
      expect(stats.saleCount, 3);
      expect(stats.isShopScope, isTrue);
    });

    test('fetchStaffSalesReport returns empty list', () async {
      when(
        () => client.rpc('get_staff_sales_report', params: any(named: 'params')),
      ).thenAnswer((_) async => <dynamic>[]);

      final rows = await repo.fetchStaffSalesReport(from: from, to: to);

      expect(rows, isEmpty);
    });

    test('fetchProductSalesReport maps rows', () async {
      when(
        () =>
            client.rpc('get_product_sales_report', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => [
          {
            'product_id': 'p1',
            'product_name': 'Soap',
            'sale_count': 2,
            'total_quantity': 5,
            'total_amount': 100,
          },
        ],
      );

      final rows = await repo.fetchProductSalesReport(from: from, to: to);

      expect(rows, hasLength(1));
      expect(rows.first, isA<ProductSalesRow>());
      expect(rows.first.productName, 'Soap');
    });

    test('fetchStockMovementReport maps rows', () async {
      when(
        () => client.rpc(
          'get_stock_movement_report',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) async => [
          {
            'movement_type': 'sale',
            'reference_id': 'r1',
            'product_id': 'p1',
            'product_name': 'Soap',
            'user_id': 'u1',
            'user_name': 'Karim',
            'quantity': 2,
            'quantity_change': -2,
            'reason': null,
            'amount': 20,
            'created_at': '2026-01-01T00:00:00Z',
          },
        ],
      );

      final rows = await repo.fetchStockMovementReport(from: from, to: to);

      expect(rows, hasLength(1));
      expect(rows.first, isA<StockMovementRow>());
      expect(rows.first.userName, 'Karim');
    });

    test('maps PostgrestException to Bengali dashboard error', () async {
      when(() => client.rpc('get_dashboard_stats', params: any(named: 'params')))
          .thenThrow(PostgrestException(''));

      await expectLater(
        repo.fetchDashboardStats(from: from, to: to),
        throwsA(
          predicate<ReportsException>(
            (e) => e.message == AppStrings.dashboardLoadFailed,
          ),
        ),
      );
    });

    test('maps PostgrestException to Bengali staff report error', () async {
      when(
        () => client.rpc('get_staff_sales_report', params: any(named: 'params')),
      ).thenThrow(PostgrestException('denied'));

      await expectLater(
        repo.fetchStaffSalesReport(from: from, to: to),
        throwsA(
          predicate<ReportsException>((e) => e.message == 'denied'),
        ),
      );
    });

    test('maps generic errors to Bengali product report error', () async {
      when(
        () =>
            client.rpc('get_product_sales_report', params: any(named: 'params')),
      ).thenThrow(Exception('network'));

      await expectLater(
        repo.fetchProductSalesReport(from: from, to: to),
        throwsA(
          predicate<ReportsException>(
            (e) => e.message == AppStrings.productReportLoadFailed,
          ),
        ),
      );
    });
  });

  group('ReportsRepository contract', () {
    test('staff report row parsing', () {
      final row = StaffSalesRow.fromJson({
        'user_id': 'u1',
        'user_name': 'Karim',
        'sale_count': 10,
        'total_amount': 500,
      });
      expect(row.userName, 'Karim');
      expect(row.saleCount, 10);
    });
  });
}
