import 'package:uuid/uuid.dart';

import '../../repositories/transaction_repository.dart';
import '../models/transaction_write_result.dart';
import '../repositories/pending_transaction_repository.dart';
import '../repositories/product_cache_repository.dart';
import '../services/connectivity_service.dart';
import '../sync_bootstrap.dart';

/// Routes transaction writes online (RPC) or offline (local queue).
class OfflineAwareTransactionRepository implements TransactionRepository {
  OfflineAwareTransactionRepository({
    required ConnectivityService connectivity,
    required TransactionRepository remote,
    required PendingTransactionRepository pendingRepo,
    required ProductCacheRepository cacheRepo,
    Uuid? uuid,
  })  : _connectivity = connectivity,
        _remote = remote,
        _pendingRepo = pendingRepo,
        _cacheRepo = cacheRepo,
        _uuid = uuid ?? const Uuid();

  final ConnectivityService _connectivity;
  final TransactionRepository _remote;
  final PendingTransactionRepository _pendingRepo;
  final ProductCacheRepository _cacheRepo;
  final Uuid _uuid;

  bool get _shouldQueueOffline =>
      SyncBootstrap.isInitialized && !_connectivity.isOnline;

  @override
  Future<TransactionWriteResult> recordSale({
    required String productId,
    required num quantity,
    String? deviceTxnId,
  }) async {
    if (_shouldQueueOffline) {
      return _enqueueSale(productId: productId, quantity: quantity);
    }
    return _tryRemote(
      () => _remote.recordSale(
        productId: productId,
        quantity: quantity,
        deviceTxnId: deviceTxnId ?? _uuid.v4(),
      ),
      onQueue: () => _enqueueSale(productId: productId, quantity: quantity),
    );
  }

  @override
  Future<TransactionWriteResult> recordStockIn({
    required String productId,
    required num quantity,
    String? deviceTxnId,
  }) async {
    if (_shouldQueueOffline) {
      return _enqueueStockIn(productId: productId, quantity: quantity);
    }
    return _tryRemote(
      () => _remote.recordStockIn(
        productId: productId,
        quantity: quantity,
        deviceTxnId: deviceTxnId ?? _uuid.v4(),
      ),
      onQueue: () => _enqueueStockIn(productId: productId, quantity: quantity),
    );
  }

  @override
  Future<TransactionWriteResult> recordAdjustment({
    required String productId,
    required num quantityChange,
    required String reason,
    String? deviceTxnId,
  }) async {
    if (_shouldQueueOffline) {
      return _enqueueAdjustment(
        productId: productId,
        quantityChange: quantityChange,
        reason: reason,
      );
    }
    return _tryRemote(
      () => _remote.recordAdjustment(
        productId: productId,
        quantityChange: quantityChange,
        reason: reason,
        deviceTxnId: deviceTxnId ?? _uuid.v4(),
      ),
      onQueue: () => _enqueueAdjustment(
        productId: productId,
        quantityChange: quantityChange,
        reason: reason,
      ),
    );
  }

  Future<TransactionWriteResult> _tryRemote(
    Future<TransactionWriteResult> Function() remoteCall, {
    required Future<TransactionWriteResult> Function() onQueue,
  }) async {
    try {
      return await remoteCall();
    } on TransactionException catch (e) {
      if (_isBusinessError(e.message)) {
        rethrow;
      }
      return await onQueue();
    } catch (_) {
      return await onQueue();
    }
  }

  Future<TransactionWriteResult> _enqueueSale({
    required String productId,
    required num quantity,
  }) async {
    await _pendingRepo.enqueueSale(productId: productId, quantity: quantity);
    await _cacheRepo.applyOptimisticStockChange(
        productId: productId, delta: -quantity);
    return TransactionWriteResult.queuedLocally;
  }

  Future<TransactionWriteResult> _enqueueStockIn({
    required String productId,
    required num quantity,
  }) async {
    await _pendingRepo.enqueueStockIn(productId: productId, quantity: quantity);
    await _cacheRepo.applyOptimisticStockChange(
        productId: productId, delta: quantity);
    return TransactionWriteResult.queuedLocally;
  }

  Future<TransactionWriteResult> _enqueueAdjustment({
    required String productId,
    required num quantityChange,
    required String reason,
  }) async {
    await _pendingRepo.enqueueAdjustment(
      productId: productId,
      quantityChange: quantityChange,
      reason: reason,
    );
    await _cacheRepo.applyOptimisticStockChange(
        productId: productId, delta: quantityChange);
    return TransactionWriteResult.queuedLocally;
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
