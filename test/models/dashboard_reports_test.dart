import 'package:flutter_test/flutter_test.dart';

import 'package:shop_stock_app/models/dashboard_stats.dart';
import 'package:shop_stock_app/models/product_sales_row.dart';
import 'package:shop_stock_app/models/staff_sales_row.dart';
import 'package:shop_stock_app/core/utils/date_range.dart';

void main() {
  group('DashboardStats', () {
    test('parses shop scope JSON', () {
      final stats = DashboardStats.fromJson({
        'role_scope': 'shop',
        'sale_count': 5,
        'total_sales_amount': 1500,
        'stock_in_count': 2,
        'adjustment_count': 1,
        'low_stock_count': 3,
      });
      expect(stats.isShopScope, isTrue);
      expect(stats.saleCount, 5);
      expect(stats.totalSalesAmount, 1500);
      expect(stats.lowStockCount, 3);
    });

    test('parses self scope JSON with defaults', () {
      final stats =
          DashboardStats.fromJson({'role_scope': 'self', 'sale_count': 1});
      expect(stats.isShopScope, isFalse);
      expect(stats.totalSalesAmount, 0);
    });
  });

  group('StaffSalesRow', () {
    test('parses report row', () {
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

  group('ProductSalesRow', () {
    test('parses report row', () {
      final row = ProductSalesRow.fromJson({
        'product_id': 'p1',
        'product_name': 'Soap',
        'sale_count': 4,
        'total_quantity': 12,
        'total_amount': 240,
      });
      expect(row.productName, 'Soap');
      expect(row.totalQuantity, 12);
    });
  });

  group('DateRange', () {
    test('today spans one local day', () {
      final range = DateRange.today();
      expect(range.to.difference(range.from).inHours, 24);
    });

    test('last7Days spans 7 days', () {
      final range = DateRange.last7Days();
      expect(range.to.difference(range.from).inDays, 7);
    });
  });
}
