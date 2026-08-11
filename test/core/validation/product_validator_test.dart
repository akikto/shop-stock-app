import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/validation/product_validator.dart';

void main() {
  group('ProductValidator.validateName', () {
    test('rejects null', () {
      expect(ProductValidator.validateName(null), isNotNull);
    });
    test('rejects empty/whitespace-only', () {
      expect(ProductValidator.validateName(''), isNotNull);
      expect(ProductValidator.validateName('   '), isNotNull);
    });
    test('accepts a normal name', () {
      expect(ProductValidator.validateName('Paracetamol 500 mg'), isNull);
    });
  });

  group('ProductValidator.validateRequiredPrice (Sale Price)', () {
    test('rejects empty', () {
      expect(ProductValidator.validateRequiredPrice(''), isNotNull);
    });
    test('rejects non-numeric text', () {
      expect(ProductValidator.validateRequiredPrice('abc'), isNotNull);
    });
    test('rejects negative values', () {
      expect(ProductValidator.validateRequiredPrice('-5'), isNotNull);
    });
    test('accepts zero', () {
      expect(ProductValidator.validateRequiredPrice('0'), isNull);
    });
    test('accepts a normal positive price', () {
      expect(ProductValidator.validateRequiredPrice('49.50'), isNull);
    });
  });

  group('ProductValidator.validateOptionalPrice (MRP / Purchase Price)', () {
    test('accepts empty (optional field)', () {
      expect(ProductValidator.validateOptionalPrice(''), isNull);
      expect(ProductValidator.validateOptionalPrice(null), isNull);
    });
    test('rejects non-numeric text when present', () {
      expect(ProductValidator.validateOptionalPrice('abc'), isNotNull);
    });
    test('rejects negative values when present', () {
      expect(ProductValidator.validateOptionalPrice('-1'), isNotNull);
    });
    test('accepts a valid positive value', () {
      expect(ProductValidator.validateOptionalPrice('60'), isNull);
    });
  });

  group('ProductValidator.validateLowStockLimit', () {
    test('accepts empty (defaults to 0 server-side)', () {
      expect(ProductValidator.validateLowStockLimit(''), isNull);
    });
    test('rejects negative values', () {
      expect(ProductValidator.validateLowStockLimit('-3'), isNotNull);
    });
    test('accepts zero', () {
      expect(ProductValidator.validateLowStockLimit('0'), isNull);
    });
    test('accepts a normal positive value', () {
      expect(ProductValidator.validateLowStockLimit('10'), isNull);
    });
  });

  group('ProductValidator.isFormValid', () {
    test('true for a fully valid set of fields', () {
      expect(
        ProductValidator.isFormValid(
          name: 'Paracetamol',
          salePrice: '55',
          mrp: '60',
          purchasePrice: '45',
          lowStockLimit: '5',
        ),
        isTrue,
      );
    });

    test('false when name is missing', () {
      expect(
        ProductValidator.isFormValid(
          name: '',
          salePrice: '55',
          mrp: '60',
          purchasePrice: '45',
          lowStockLimit: '5',
        ),
        isFalse,
      );
    });

    test('false when sale price is negative', () {
      expect(
        ProductValidator.isFormValid(
          name: 'Paracetamol',
          salePrice: '-10',
          mrp: '60',
          purchasePrice: '45',
          lowStockLimit: '5',
        ),
        isFalse,
      );
    });

    test('false when low-stock limit is negative', () {
      expect(
        ProductValidator.isFormValid(
          name: 'Paracetamol',
          salePrice: '55',
          mrp: '60',
          purchasePrice: '45',
          lowStockLimit: '-1',
        ),
        isFalse,
      );
    });

    test('true when optional MRP/purchase price are omitted entirely', () {
      expect(
        ProductValidator.isFormValid(
          name: 'Paracetamol',
          salePrice: '55',
          mrp: '',
          purchasePrice: '',
          lowStockLimit: '',
        ),
        isTrue,
      );
    });
  });
}
