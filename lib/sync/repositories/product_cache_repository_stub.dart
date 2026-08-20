import '../models/cached_product.dart' as models;

/// Web stub — never used when [SyncBootstrap] skips initialization on web.
class ProductCacheRepository {
  ProductCacheRepository(dynamic db);

  Future<void> replaceAll(List<models.CachedProduct> products) async {}

  Future<List<models.CachedProduct>> fetchActive({String search = ''}) async => [];

  Future<models.CachedProduct?> getById(String id) async => null;

  Future<void> applyOptimisticStockChange({
    required String productId,
    required num delta,
  }) async {}

  Future<DateTime?> lastProductSyncAt() async => null;
}
