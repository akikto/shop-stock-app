import 'package:flutter_test/flutter_test.dart';

import 'package:shop_stock_app/models/dashboard_stats.dart';
import 'package:shop_stock_app/models/product_sales_row.dart';
import 'package:shop_stock_app/models/staff_sales_row.dart';
import 'package:shop_stock_app/models/stock_movement_row.dart';

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
      expect(stats.adjustmentCount, 1);
    });

    test('parses self scope JSON with defaults', () {
      final stats =
          DashboardStats.fromJson({'role_scope': 'self', 'sale_count': 1});
      expect(stats.isShopScope, isFalse);
      expect(stats.totalSalesAmount, 0);
      expect(stats.adjustmentCount, 0);
      expect(stats.lowStockCount, 0);
    });

    test('handles null and missing numeric fields', () {
      final stats = DashboardStats.fromJson({
        'role_scope': 'shop',
        'sale_count': null,
        'total_sales_amount': null,
      });
      expect(stats.saleCount, 0);
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

    test('defaults unknown user name', () {
      final row = StaffSalesRow.fromJson({
        'user_id': 'u1',
        'sale_count': 1,
        'total_amount': 10,
      });
      expect(row.userName, 'Unknown');
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

  group('StockMovementRow', () {
    test('parses movement row', () {
      final row = StockMovementRow.fromJson({
        'movement_type': 'stock_in',
        'reference_id': 'r1',
        'product_id': 'p1',
        'product_name': 'Soap',
        'user_id': 'u1',
        'user_name': 'Karim',
        'quantity': 5,
        'quantity_change': 5,
        'reason': null,
        'amount': null,
        'created_at': '2026-01-01T12:00:00Z',
      });
      expect(row.movementType, 'stock_in');
      expect(row.quantityChange, 5);
    });
  });
}
