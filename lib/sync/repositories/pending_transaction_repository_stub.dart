import '../models/pending_transaction.dart' as models;
import '../models/pending_transaction_status.dart';
import '../models/pending_transaction_type.dart';

/// Web stub — never used when [SyncBootstrap] skips initialization on web.
class PendingTransactionRepository {
  PendingTransactionRepository(dynamic db, {dynamic uuid});

  Future<models.PendingTransaction> enqueueSale({
    required String productId,
    required num quantity,
  }) async {
    throw UnsupportedError('Offline sync is not available on web');
  }

  Future<models.PendingTransaction> enqueueStockIn({
    required String productId,
    required num quantity,
  }) async {
    throw UnsupportedError('Offline sync is not available on web');
  }

  Future<models.PendingTransaction> enqueueAdjustment({
    required String productId,
    required num quantityChange,
    required String reason,
  }) async {
    throw UnsupportedError('Offline sync is not available on web');
  }

  Future<List<models.PendingTransaction>> fetchFifoPending() async => [];

  Future<List<models.PendingTransaction>> fetchVisible() async => [];

  Future<int> countActionable() async => 0;

  Future<models.PendingTransaction?> getByLocalId(int localId) async => null;

  Future<void> markSyncing(int localId) async {}

  Future<void> markSynced(int localId) async {}

  Future<void> markFailed(int localId, String error) async {}

  Future<void> markPending(int localId) async {}

  Future<void> deleteFailed(int localId) async {}
}
