import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/features/products/providers/product_providers.dart';
import 'package:shop_stock_app/features/sale/presentation/sale_screen.dart';
import 'package:shop_stock_app/features/transactions/providers/transaction_providers.dart';
import 'package:shop_stock_app/models/product.dart';
import 'package:shop_stock_app/repositories/product_repository.dart';
import 'package:shop_stock_app/repositories/transaction_repository.dart';

Product _lowStockProduct({num currentStock = 2}) {
  return Product(
    id: 'prod-1',
    name: 'Paracetamol 500 mg',
    salePrice: 10,
    currentStock: currentStock,
    lowStockLimit: 5,
    isActive: true,
    createdBy: 'owner-1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    // No photo — avoids needing to stub the photo/signed-URL service in this test.
  );
}

/// Minimal fake — only fetchProducts is exercised by the picker grid.
class FakeProductRepository implements ProductRepository {
  FakeProductRepository(this.products);
  final List<Product> products;

  @override
  Future<List<Product>> fetchProducts({
    String search = '',
    bool activeOnly = true,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    if (offset > 0) return [];
    return products;
  }

  @override
  Future<List<String>> fetchDistinctCategories() async => [];

  @override
  Future<Product?> fetchProductById(String id) async =>
      products.where((p) => p.id == id).firstOrNull;

  @override
  Future<Product> createProduct({
    required String name,
    String? photoUrl,
    String? photoThumbUrl,
    String? company,
    String? category,
    String? packSize,
    num? mrp,
    num? purchasePrice,
    required num salePrice,
    num lowStockLimit = 0,
    DateTime? expiryDate,
    String? composition,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Product> updateProduct({
    required String id,
    required String name,
    String? photoUrl,
    String? photoThumbUrl,
    String? company,
    String? category,
    String? packSize,
    num? mrp,
    num? purchasePrice,
    required num salePrice,
    num lowStockLimit = 0,
    DateTime? expiryDate,
    String? composition,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Product> deactivateProduct(String id) async => throw UnimplementedError();

  @override
  Future<Product> activateProduct(String id) async => throw UnimplementedError();
}

class RecordSaleCall {
  RecordSaleCall(this.productId, this.quantity);
  final String productId;
  final num quantity;
}

class FakeTransactionRepository implements TransactionRepository {
  final List<RecordSaleCall> saleCalls = [];

  @override
  Future<void> recordSale({required String productId, required num quantity}) async {
    saleCalls.add(RecordSaleCall(productId, quantity));
  }

  @override
  Future<void> recordStockIn({required String productId, required num quantity}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> recordAdjustment({
    required String productId,
    required num quantityChange,
    required String reason,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('selecting a quantity above available stock shows an error and never calls recordSale',
      (tester) async {
    final product = _lowStockProduct(currentStock: 2);
    final fakeProducts = FakeProductRepository([product]);
    final fakeTransactions = FakeTransactionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(fakeProducts),
          transactionRepositoryProvider.overrideWithValue(fakeTransactions),
        ],
        child: const MaterialApp(home: SaleScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the product card to open the quantity sheet.
    await tester.tap(find.text('Paracetamol 500 mg'));
    await tester.pumpAndSettle();

    // Increase quantity from 1 to 3 (above the stock of 2) by tapping "+" twice.
    final incrementButton = find.byIcon(Icons.add).last;
    await tester.tap(incrementButton);
    await tester.pump();
    await tester.tap(incrementButton);
    await tester.pump();

    // Confirm the sale.
    await tester.tap(find.text(AppStrings.confirmSale));
    await tester.pump();

    expect(find.text(AppStrings.insufficientStock), findsOneWidget);
    expect(fakeTransactions.saleCalls, isEmpty, reason: 'must not call the RPC when quantity exceeds stock');
  });

  testWidgets('selecting a quantity within available stock calls recordSale with the right parameters',
      (tester) async {
    final product = _lowStockProduct(currentStock: 5);
    final fakeProducts = FakeProductRepository([product]);
    final fakeTransactions = FakeTransactionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(fakeProducts),
          transactionRepositoryProvider.overrideWithValue(fakeTransactions),
        ],
        child: const MaterialApp(home: SaleScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paracetamol 500 mg'));
    await tester.pumpAndSettle();

    // Default quantity is 1, well within stock of 5 — confirm directly.
    await tester.tap(find.text(AppStrings.confirmSale));
    await tester.pump();
    await tester.pump(); // allow the async recordSale + refresh to complete

    expect(fakeTransactions.saleCalls.length, 1);
    expect(fakeTransactions.saleCalls.first.productId, 'prod-1');
    expect(fakeTransactions.saleCalls.first.quantity, 1);
  });
}
