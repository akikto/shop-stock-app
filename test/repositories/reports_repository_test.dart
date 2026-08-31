import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/models/dashboard_stats.dart';
import 'package:shop_stock_app/models/product_sales_row.dart';
import 'package:shop_stock_app/models/staff_sales_row.dart';
import 'package:shop_stock_app/models/stock_movement_row.dart';
import 'package:shop_stock_app/repositories/reports_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeReportsRepository implements ReportsRepository {
  FakeReportsRepository({
    this.dashboardStats = const DashboardStats(
      roleScope: 'shop',
      saleCount: 3,
      totalSalesAmount: 300,
      stockInCount: 1,
      adjustmentCount: 0,
      lowStockCount: 2,
    ),
    this.staffRows = const [],
    this.productRows = const [],
    this.movementRows = const [],
    this.failureMessage,
  });

  final DashboardStats dashboardStats;
  final List<StaffSalesRow> staffRows;
  final List<ProductSalesRow> productRows;
  final List<StockMovementRow> movementRows;
  final String? failureMessage;

  @override
  Future<DashboardStats> fetchDashboardStats(
      {required DateTime from, required DateTime to}) async {
    if (failureMessage != null) {
      throw ReportsException(failureMessage!);
    }
    return dashboardStats;
  }

  @override
  Future<List<StaffSalesRow>> fetchStaffSalesReport(
      {required DateTime from, required DateTime to}) async {
    if (failureMessage != null) {
      throw ReportsException(failureMessage!);
    }
    return staffRows;
  }

  @override
  Future<List<ProductSalesRow>> fetchProductSalesReport(
      {required DateTime from, required DateTime to}) async {
    if (failureMessage != null) {
      throw ReportsException(failureMessage!);
    }
    return productRows;
  }

  @override
  Future<List<StockMovementRow>> fetchStockMovementReport(
      {required DateTime from, required DateTime to}) async {
    if (failureMessage != null) {
      throw ReportsException(failureMessage!);
    }
    return movementRows;
  }
}

void main() {
  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 1, 2);

  group('mapReportsException', () {
    test('uses server message when present', () {
      final exception = mapReportsException(
        PostgrestException(message: 'denied'),
        AppStrings.dashboardLoadFailed,
      );

      expect(exception.message, 'denied');
    });

    test('uses Bengali fallback when PostgREST message is empty', () {
      final exception = mapReportsException(
        PostgrestException(message: ''),
        AppStrings.staffReportLoadFailed,
      );

      expect(exception.message, AppStrings.staffReportLoadFailed);
    });
  });

  group('ReportsRepository contract', () {
    test('fetchDashboardStats returns parsed stats', () async {
      final repo = FakeReportsRepository();

      final stats = await repo.fetchDashboardStats(from: from, to: to);

      expect(stats.isShopScope, isTrue);
      expect(stats.saleCount, 3);
    });

    test('fetchStaffSalesReport returns empty list', () async {
      final repo = FakeReportsRepository();

      final rows = await repo.fetchStaffSalesReport(from: from, to: to);

      expect(rows, isEmpty);
    });

    test('fetchProductSalesReport maps rows', () async {
      final repo = FakeReportsRepository(
        productRows: const [
          ProductSalesRow(
            productId: 'p1',
            productName: 'Soap',
            saleCount: 2,
            totalQuantity: 5,
            totalAmount: 100,
          ),
        ],
      );

      final rows = await repo.fetchProductSalesReport(from: from, to: to);

      expect(rows, hasLength(1));
      expect(rows.first.productName, 'Soap');
    });

    test('fetchStockMovementReport maps rows', () async {
      final repo = FakeReportsRepository(
        movementRows: [
          StockMovementRow(
            movementType: 'sale',
            referenceId: 'r1',
            productId: 'p1',
            productName: 'Soap',
            userId: 'u1',
            userName: 'Karim',
            quantity: 2,
            quantityChange: -2,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );

      final rows = await repo.fetchStockMovementReport(from: from, to: to);

      expect(rows, hasLength(1));
      expect(rows.first.userName, 'Karim');
    });

    test('throws ReportsException with Bengali message on failure', () async {
      final repo = FakeReportsRepository(
        failureMessage: AppStrings.productReportLoadFailed,
      );

      await expectLater(
        repo.fetchProductSalesReport(from: from, to: to),
        throwsA(
          predicate<ReportsException>(
            (e) => e.message == AppStrings.productReportLoadFailed,
          ),
        ),
      );
    });

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
