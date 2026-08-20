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
import 'package:shop_stock_app/sync/models/transaction_write_result.dart';

class FakeQueuedTransactionRepository implements TransactionRepository {
  @override
  Future<TransactionWriteResult> recordSale({
    required String productId,
    required num quantity,
    String? deviceTxnId,
  }) async =>
      TransactionWriteResult.queuedLocally;

  @override
  Future<TransactionWriteResult> recordStockIn({
    required String productId,
    required num quantity,
    String? deviceTxnId,
  }) async =>
      TransactionWriteResult.queuedLocally;

  @override
  Future<TransactionWriteResult> recordAdjustment({
    required String productId,
    required num quantityChange,
    required String reason,
    String? deviceTxnId,
  }) async =>
      TransactionWriteResult.queuedLocally;
}

class FakeProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts({
    String search = '',
    bool activeOnly = true,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async =>
      [
        Product(
          id: 'prod-1',
          name: 'Paracetamol 500 mg',
          salePrice: 10,
          currentStock: 5,
          lowStockLimit: 2,
          isActive: true,
          createdBy: 'owner-1',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ];

  @override
  Future<List<String>> fetchDistinctCategories() async => [];

  @override
  Future<Product?> fetchProductById(String id) async => null;

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
  Future<Product> deactivateProduct(String id) async =>
      throw UnimplementedError();

  @override
  Future<Product> activateProduct(String id) async =>
      throw UnimplementedError();
}

void main() {
  testWidgets('queued offline sale shows Bengali saved-locally snackbar',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(FakeProductRepository()),
          transactionRepositoryProvider
              .overrideWithValue(FakeQueuedTransactionRepository()),
        ],
        child: const MaterialApp(home: SaleScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paracetamol 500 mg'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.confirmSale));
    await tester.pump();
    await tester.pump();

    expect(find.text(AppStrings.savedLocallyWillSync), findsOneWidget);
  });
}
