import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/sync/database/sync_database.dart';
import 'package:shop_stock_app/sync/models/cached_product.dart' as models;
import 'package:shop_stock_app/sync/repositories/product_cache_repository.dart';

void main() {
  late SyncDatabase db;
  late ProductCacheRepository repo;

  setUp(() async {
    db = SyncDatabase(NativeDatabase.memory());
    repo = ProductCacheRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('replaceAll stores active products and fetchActive filters search',
      () async {
    await repo.replaceAll([
      models.CachedProduct(
        id: '1',
        name: 'Paracetamol',
        salePrice: 10,
        currentStock: 5,
        lowStockLimit: 2,
        isActive: true,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
      models.CachedProduct(
        id: '2',
        name: 'Ibuprofen',
        salePrice: 12,
        currentStock: 3,
        lowStockLimit: 1,
        isActive: false,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    ]);

    final active = await repo.fetchActive();
    expect(active.length, 1);
    expect(active.first.name, 'Paracetamol');

    final search = await repo.fetchActive(search: 'para');
    expect(search.length, 1);
  });

  test('applyOptimisticStockChange adjusts cached stock', () async {
    await repo.replaceAll([
      models.CachedProduct(
        id: '1',
        name: 'Item',
        salePrice: 10,
        currentStock: 10,
        lowStockLimit: 2,
        isActive: true,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    ]);
    await repo.applyOptimisticStockChange(productId: '1', delta: -2);
    final product = await repo.getById('1');
    expect(product!.currentStock, 8);
  });
}
