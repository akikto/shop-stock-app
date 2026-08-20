import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/models/stock_entry.dart';

void main() {
  group('StockEntry', () {
    test('fromJson maps all fields correctly', () {
      final json = {
        'id': 'entry-1',
        'product_id': 'prod-1',
        'user_id': 'user-1',
        'quantity': 50,
        'device_txn_id': 'txn-1',
        'created_at': '2026-08-20T10:00:00Z',
      };

      final entry = StockEntry.fromJson(json);

      expect(entry.id, 'entry-1');
      expect(entry.productId, 'prod-1');
      expect(entry.userId, 'user-1');
      expect(entry.quantity, 50);
      expect(entry.deviceTxnId, 'txn-1');
      expect(entry.createdAt, DateTime.utc(2026, 8, 20, 10));
    });
  });
}
