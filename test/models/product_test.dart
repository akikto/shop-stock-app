import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/models/product.dart';

Map<String, dynamic> _baseJson({
  num currentStock = 10,
  num lowStockLimit = 5,
  num salePrice = 100,
}) {
  return {
    'id': 'prod-1',
    'name': 'Paracetamol 500 mg',
    'photo_url': 'products/abc/photo.jpg',
    'photo_thumb_url': 'products/abc/thumb.jpg',
    'company': 'Square',
    'category': 'Medicine',
    'pack_size': '10 tablets',
    'mrp': 50,
    'purchase_price': 40,
    'sale_price': salePrice,
    'current_stock': currentStock,
    'low_stock_limit': lowStockLimit,
    'is_active': true,
    'created_by': 'user-1',
    'created_at': '2026-01-01T10:00:00Z',
    'updated_at': '2026-01-02T10:00:00Z',
  };
}

void main() {
  group('Product.fromJson', () {
    test('parses a well-formed product row', () {
      final product = Product.fromJson(_baseJson());

      expect(product.id, 'prod-1');
      expect(product.name, 'Paracetamol 500 mg');
      expect(product.photoUrl, 'products/abc/photo.jpg');
      expect(product.company, 'Square');
      expect(product.salePrice, 100);
      expect(product.currentStock, 10);
      expect(product.isActive, isTrue);
    });

    test('parses nullable fields as null when absent', () {
      final json = _baseJson()
        ..['photo_url'] = null
        ..['photo_thumb_url'] = null
        ..['company'] = null
        ..['mrp'] = null
        ..['purchase_price'] = null;

      final product = Product.fromJson(json);

      expect(product.photoUrl, isNull);
      expect(product.company, isNull);
      expect(product.mrp, isNull);
      expect(product.purchasePrice, isNull);
    });
  });

  group('Product.isLowStock', () {
    test('is true when current stock is at or below the low-stock limit', () {
      final product = Product.fromJson(_baseJson(currentStock: 5, lowStockLimit: 5));
      expect(product.isLowStock, isTrue);
    });

    test('is true when current stock is below the low-stock limit', () {
      final product = Product.fromJson(_baseJson(currentStock: 2, lowStockLimit: 5));
      expect(product.isLowStock, isTrue);
    });

    test('is false when current stock is comfortably above the limit', () {
      final product = Product.fromJson(_baseJson(currentStock: 50, lowStockLimit: 5));
      expect(product.isLowStock, isFalse);
    });

    test('is true at zero stock even with a zero low-stock limit (edge case)', () {
      final product = Product.fromJson(_baseJson(currentStock: 0, lowStockLimit: 0));
      expect(product.isLowStock, isTrue);
    });
  });
}
