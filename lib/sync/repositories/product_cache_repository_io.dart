import 'package:drift/drift.dart';

import '../database/sync_database_io.dart' as drift_db;
import '../models/cached_product.dart' as models;

class ProductCacheRepository {
  ProductCacheRepository(drift_db.SyncDatabase db) : _db = db;

  final drift_db.SyncDatabase _db;

  Future<void> replaceAll(List<models.CachedProduct> products) async {
    await _db.transaction(() async {
      await _db.delete(_db.cachedProducts).go();
      if (products.isEmpty) return;
      await _db.batch((batch) {
        batch.insertAll(
          _db.cachedProducts,
          products.map(_toRow).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
      await _db.into(_db.syncMetadata).insertOnConflictUpdate(
            drift_db.SyncMetadataCompanion(
              id: const Value(1),
              lastProductSyncAt: Value(DateTime.now()),
            ),
          );
    });
  }

  Future<List<models.CachedProduct>> fetchActive({String search = ''}) async {
    final query = _db.select(_db.cachedProducts)
      ..where((t) => t.isActive.equals(true));
    final rows = await query.get();
    final normalized = search.trim().toLowerCase();
    final filtered = normalized.isEmpty
        ? rows
        : rows.where((r) => r.name.toLowerCase().contains(normalized)).toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered.map(_fromRow).toList();
  }

  Future<models.CachedProduct?> getById(String id) async {
    final row = await (_db.select(_db.cachedProducts)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<void> applyOptimisticStockChange({
    required String productId,
    required num delta,
  }) async {
    final row = await (_db.select(_db.cachedProducts)
          ..where((t) => t.id.equals(productId)))
        .getSingleOrNull();
    if (row == null) return;
    final newStock = row.currentStock + delta;
    await (_db.update(_db.cachedProducts)..where((t) => t.id.equals(productId)))
        .write(
      drift_db.CachedProductsCompanion(
        currentStock: Value(newStock),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<DateTime?> lastProductSyncAt() async {
    final row = await (_db.select(_db.syncMetadata)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    return row?.lastProductSyncAt;
  }

  drift_db.CachedProductsCompanion _toRow(models.CachedProduct p) {
    return drift_db.CachedProductsCompanion.insert(
      id: p.id,
      name: p.name,
      salePrice: p.salePrice.toDouble(),
      currentStock: p.currentStock.toDouble(),
      lowStockLimit: p.lowStockLimit.toDouble(),
      isActive: p.isActive,
      photoThumbUrl: Value(p.photoThumbUrl),
      company: Value(p.company),
      category: Value(p.category),
      updatedAt: p.updatedAt,
    );
  }

  models.CachedProduct _fromRow(drift_db.CachedProduct row) {
    return models.CachedProduct(
      id: row.id,
      name: row.name,
      salePrice: row.salePrice,
      currentStock: row.currentStock,
      lowStockLimit: row.lowStockLimit,
      isActive: row.isActive,
      photoThumbUrl: row.photoThumbUrl,
      company: row.company,
      category: row.category,
      updatedAt: row.updatedAt,
    );
  }
}
