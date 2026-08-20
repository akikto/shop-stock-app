import '../../repositories/product_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../models/cached_product.dart';
import '../models/pending_transaction.dart';
import '../models/pending_transaction_type.dart';
import '../repositories/pending_transaction_repository.dart';
import '../repositories/product_cache_repository.dart';

typedef SyncInvalidateCallback = void Function();

/// Replays the local pending queue FIFO against server RPCs.
class SyncEngine {
  SyncEngine({
    required PendingTransactionRepository pendingRepo,
    required ProductCacheRepository cacheRepo,
    required ProductRepository productRepo,
    required TransactionRepository remoteRepo,
    SyncInvalidateCallback? onInvalidate,
  })  : _pendingRepo = pendingRepo,
        _cacheRepo = cacheRepo,
        _productRepo = productRepo,
        _remoteRepo = remoteRepo,
        _onInvalidate = onInvalidate;

  final PendingTransactionRepository _pendingRepo;
  final ProductCacheRepository _cacheRepo;
  final ProductRepository _productRepo;
  final TransactionRepository _remoteRepo;
  final SyncInvalidateCallback? _onInvalidate;

  bool _running = false;

  Future<void> refreshProductCache() async {
    const pageSize = 50;
    var offset = 0;
    final all = <CachedProduct>[];
    while (true) {
      final batch = await _productRepo.fetchProducts(
        activeOnly: true,
        offset: offset,
        limit: pageSize,
      );
      if (batch.isEmpty) break;
      all.addAll(
        batch.map(
          (p) => CachedProduct(
            id: p.id,
            name: p.name,
            salePrice: p.salePrice,
            currentStock: p.currentStock,
            lowStockLimit: p.lowStockLimit,
            isActive: p.isActive,
            photoThumbUrl: p.photoThumbUrl,
            company: p.company,
            category: p.category,
            updatedAt: p.updatedAt,
          ),
        ),
      );
      if (batch.length < pageSize) break;
      offset += batch.length;
    }
    await _cacheRepo.replaceAll(all);
  }

  Future<bool> processQueue() async {
    if (_running) return false;
    _running = true;
    try {
      var syncedAny = false;
      final pending = await _pendingRepo.fetchFifoPending();
      for (final item in pending) {
        final ok = await _syncOne(item);
        if (ok) syncedAny = true;
      }
      if (syncedAny) {
        await refreshProductCache();
        _onInvalidate?.call();
      }
      return syncedAny;
    } finally {
      _running = false;
    }
  }

  Future<bool> _syncOne(PendingTransaction item) async {
    await _pendingRepo.markSyncing(item.localId);
    try {
      switch (item.type) {
        case PendingTransactionType.sale:
          await _remoteRepo.recordSale(
            productId: item.productId,
            quantity: item.quantity!,
            deviceTxnId: item.deviceTxnId,
          );
        case PendingTransactionType.stockIn:
          await _remoteRepo.recordStockIn(
            productId: item.productId,
            quantity: item.quantity!,
            deviceTxnId: item.deviceTxnId,
          );
        case PendingTransactionType.adjustment:
          await _remoteRepo.recordAdjustment(
            productId: item.productId,
            quantityChange: item.quantityChange!,
            reason: item.reason ?? '',
            deviceTxnId: item.deviceTxnId,
          );
      }
      await _pendingRepo.markSynced(item.localId);
      return true;
    } on TransactionException catch (e) {
      if (_isBusinessError(e.message)) {
        await _pendingRepo.markFailed(item.localId, e.message);
      } else {
        await _pendingRepo.markPending(item.localId);
      }
      return false;
    } catch (e) {
      await _pendingRepo.markPending(item.localId);
      return false;
    }
  }

  Future<void> retryFailed(int localId) async {
    await _pendingRepo.markPending(localId);
    await processQueue();
  }

  bool _isBusinessError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('insufficient stock') ||
        lower.contains('negative stock') ||
        lower.contains('not found or inactive') ||
        lower.contains('only a manager or owner') ||
        lower.contains('not active') ||
        lower.contains('quantity must be greater than zero') ||
        lower.contains('adjustment quantity cannot be zero') ||
        lower.contains('reason is required');
  }
}
