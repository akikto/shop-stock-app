import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/models/stock_adjustment.dart';

void main() {
  group('StockAdjustment', () {
    test('fromJson maps all fields correctly', () {
      final json = {
        'id': 'adj-1',
        'product_id': 'prod-1',
        'user_id': 'user-1',
        'quantity_change': -5,
        'reason': 'Damaged goods',
        'device_txn_id': 'txn-1',
        'created_at': '2026-08-20T10:00:00Z',
      };

      final adj = StockAdjustment.fromJson(json);

      expect(adj.id, 'adj-1');
      expect(adj.productId, 'prod-1');
      expect(adj.userId, 'user-1');
      expect(adj.quantityChange, -5);
      expect(adj.reason, 'Damaged goods');
      expect(adj.deviceTxnId, 'txn-1');
      expect(adj.createdAt, DateTime.utc(2026, 8, 20, 10));
    });
  });
}
