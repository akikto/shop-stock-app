import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/services/report_calculations.dart';

void main() {
  group('aggregateDailySales', () {
    test('groups sales by local calendar day and sums totals', () {
      final rows = [
        {'created_at': '2026-01-01T10:00:00Z', 'total_amount': 100},
        {'created_at': '2026-01-01T14:00:00Z', 'total_amount': 50},
        {'created_at': '2026-01-02T09:00:00Z', 'total_amount': 200},
      ];
      final points = aggregateDailySales(rows);

      expect(points.length, 2);
      expect(points[0].totalAmount, 150);
      expect(points[0].saleCount, 2);
      expect(points[1].totalAmount, 200);
      expect(points[1].saleCount, 1);
    });

    test('returns an empty list for no sales', () {
      expect(aggregateDailySales([]), isEmpty);
    });

    test('results are sorted chronologically', () {
      final rows = [
        {'created_at': '2026-01-05T10:00:00Z', 'total_amount': 10},
        {'created_at': '2026-01-01T10:00:00Z', 'total_amount': 20},
        {'created_at': '2026-01-03T10:00:00Z', 'total_amount': 30},
      ];
      final points = aggregateDailySales(rows);
      expect(points[0].date.day, 1);
      expect(points[1].date.day, 3);
      expect(points[2].date.day, 5);
    });
  });

  group('aggregateStaffSales', () {
    test('groups by user_id, sums totals, resolves names', () {
      final rows = [
        {'user_id': 'u1', 'total_amount': 100},
        {'user_id': 'u1', 'total_amount': 50},
        {'user_id': 'u2', 'total_amount': 200},
      ];
      final summaries = aggregateStaffSales(rows, {'u1': 'Karim', 'u2': 'Rahim'});

      expect(summaries.length, 2);
      // Sorted descending by total — u2 (200) before u1 (150).
      expect(summaries[0].userName, 'Rahim');
      expect(summaries[0].totalAmount, 200);
      expect(summaries[1].userName, 'Karim');
      expect(summaries[1].totalAmount, 150);
      expect(summaries[1].saleCount, 2);
    });

    test('falls back to the raw id when a name is not resolvable', () {
      final rows = [
        {'user_id': 'unknown-user', 'total_amount': 10},
      ];
      final summaries = aggregateStaffSales(rows, {});
      expect(summaries.single.userName, 'unknown-user');
    });
  });

  group('aggregateProductSales', () {
    test('groups by product_id, sums quantity and amount, reads embedded product name', () {
      final rows = [
        {
          'product_id': 'p1',
          'quantity': 2,
          'total_amount': 40,
          'products': {'name': 'Paracetamol'}
        },
        {
          'product_id': 'p1',
          'quantity': 3,
          'total_amount': 60,
          'products': {'name': 'Paracetamol'}
        },
        {
          'product_id': 'p2',
          'quantity': 1,
          'total_amount': 500,
          'products': {'name': 'Vitamin C'}
        },
      ];
      final summaries = aggregateProductSales(rows);

      expect(summaries.length, 2);
      // Sorted descending by amount — Vitamin C (500) before Paracetamol (100).
      expect(summaries[0].productName, 'Vitamin C');
      expect(summaries[1].productName, 'Paracetamol');
      expect(summaries[1].totalQuantity, 5);
      expect(summaries[1].totalAmount, 100);
    });
  });

  group('aggregateStockMovement', () {
    test('combines stock-in, sold, and adjustment quantities per product', () {
      final stockIn = [
        {
          'product_id': 'p1',
          'quantity': 10,
          'products': {'name': 'Paracetamol'}
        },
      ];
      final sales = [
        {
          'product_id': 'p1',
          'quantity': 4,
          'products': {'name': 'Paracetamol'}
        },
      ];
      final adjustments = [
        {
          'product_id': 'p1',
          'quantity_change': -1,
          'products': {'name': 'Paracetamol'}
        },
      ];

      final summaries = aggregateStockMovement(stockInRows: stockIn, salesRows: sales, adjustmentRows: adjustments);

      expect(summaries.length, 1);
      final p1 = summaries.single;
      expect(p1.stockIn, 10);
      expect(p1.sold, 4);
      expect(p1.adjustedNet, -1);
      expect(p1.netChange, 10 - 4 - 1); // = 5
    });

    test('includes a product that only appears in one of the three sources', () {
      final stockIn = [
        {
          'product_id': 'p2',
          'quantity': 5,
          'products': {'name': 'Vitamin C'}
        },
      ];
      final summaries = aggregateStockMovement(stockInRows: stockIn, salesRows: [], adjustmentRows: []);

      expect(summaries.length, 1);
      expect(summaries.single.stockIn, 5);
      expect(summaries.single.sold, 0);
      expect(summaries.single.adjustedNet, 0);
      expect(summaries.single.netChange, 5);
    });

    test('returns an empty list when there is no movement at all', () {
      final summaries = aggregateStockMovement(stockInRows: [], salesRows: [], adjustmentRows: []);
      expect(summaries, isEmpty);
    });

    test('falls back to the raw product id when no embedded name is present', () {
      final stockIn = [
        {'product_id': 'p3', 'quantity': 1},
      ];
      final summaries = aggregateStockMovement(stockInRows: stockIn, salesRows: [], adjustmentRows: []);
      expect(summaries.single.productName, 'p3');
    });
  });
}
