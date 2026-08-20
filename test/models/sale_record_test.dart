import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/models/sale_record.dart';

void main() {
  group('SaleRecord', () {
    test('fromJson maps all fields correctly', () {
      final json = {
        'id': 'sale-1',
        'product_id': 'prod-1',
        'user_id': 'user-1',
        'quantity': 3,
        'unit_price_at_sale': 25.50,
        'total_amount': 76.50,
        'device_txn_id': 'txn-1',
        'created_at': '2026-08-20T10:00:00Z',
      };

      final sale = SaleRecord.fromJson(json);

      expect(sale.id, 'sale-1');
      expect(sale.productId, 'prod-1');
      expect(sale.userId, 'user-1');
      expect(sale.quantity, 3);
      expect(sale.unitPriceAtSale, 25.50);
      expect(sale.totalAmount, 76.50);
      expect(sale.deviceTxnId, 'txn-1');
      expect(sale.createdAt, DateTime.utc(2026, 8, 20, 10));
    });
  });
}
