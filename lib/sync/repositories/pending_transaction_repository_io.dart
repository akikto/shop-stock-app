import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/sync_database_io.dart' as drift_db;
import '../models/pending_transaction.dart' as models;
import '../models/pending_transaction_status.dart';
import '../models/pending_transaction_type.dart';

class PendingTransactionRepository {
  PendingTransactionRepository(drift_db.SyncDatabase db, {Uuid? uuid})
      : _db = db,
        _uuid = uuid ?? const Uuid();

  final drift_db.SyncDatabase _db;
  final Uuid _uuid;

  Future<models.PendingTransaction> enqueueSale({
    required String productId,
    required num quantity,
  }) async {
    return _enqueue(
      type: PendingTransactionType.sale,
      productId: productId,
      quantity: quantity,
    );
  }

  Future<models.PendingTransaction> enqueueStockIn({
    required String productId,
    required num quantity,
  }) async {
    return _enqueue(
      type: PendingTransactionType.stockIn,
      productId: productId,
      quantity: quantity,
    );
  }

  Future<models.PendingTransaction> enqueueAdjustment({
    required String productId,
    required num quantityChange,
    required String reason,
  }) async {
    return _enqueue(
      type: PendingTransactionType.adjustment,
      productId: productId,
      quantityChange: quantityChange,
      reason: reason,
    );
  }

  Future<models.PendingTransaction> _enqueue({
    required PendingTransactionType type,
    required String productId,
    num? quantity,
    num? quantityChange,
    String? reason,
  }) async {
    final deviceTxnId = _uuid.v4();
    final id = await _db.into(_db.pendingTransactions).insert(
          drift_db.PendingTransactionsCompanion.insert(
            deviceTxnId: deviceTxnId,
            type: type.storageValue,
            productId: productId,
            quantity: quantity == null
                ? const Value.absent()
                : Value(quantity.toDouble()),
            quantityChange: quantityChange == null
                ? const Value.absent()
                : Value(quantityChange.toDouble()),
            reason: Value(reason),
            createdAt: DateTime.now(),
            status: PendingTransactionStatus.pending.storageValue,
          ),
        );
    return (await getByLocalId(id))!;
  }

  Future<List<models.PendingTransaction>> fetchFifoPending() async {
    final rows = await (_db.select(_db.pendingTransactions)
          ..where((t) =>
              t.status.equals(PendingTransactionStatus.pending.storageValue))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return await _mapRows(rows);
  }

  Future<List<models.PendingTransaction>> fetchVisible() async {
    final rows = await (_db.select(_db.pendingTransactions)
          ..where(
            (t) => t.status.isIn([
              PendingTransactionStatus.pending.storageValue,
              PendingTransactionStatus.failed.storageValue,
              PendingTransactionStatus.syncing.storageValue,
            ]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return await _mapRows(rows);
  }

  Future<int> countActionable() async {
    final pending = await (_db.select(_db.pendingTransactions)
          ..where((t) =>
              t.status.equals(PendingTransactionStatus.pending.storageValue)))
        .get();
    final failed = await (_db.select(_db.pendingTransactions)
          ..where((t) =>
              t.status.equals(PendingTransactionStatus.failed.storageValue)))
        .get();
    return pending.length + failed.length;
  }

  Future<models.PendingTransaction?> getByLocalId(int localId) async {
    final row = await (_db.select(_db.pendingTransactions)
          ..where((t) => t.id.equals(localId)))
        .getSingleOrNull();
    if (row == null) return null;
    return (await _mapRows([row])).first;
  }

  Future<void> markSyncing(int localId) async {
    await (_db.update(_db.pendingTransactions)
          ..where((t) => t.id.equals(localId)))
        .write(
      drift_db.PendingTransactionsCompanion(
        status: Value(PendingTransactionStatus.syncing.storageValue),
        attemptCount: Value(await _nextAttemptCount(localId)),
      ),
    );
  }

  Future<void> markSynced(int localId) async {
    await (_db.update(_db.pendingTransactions)
          ..where((t) => t.id.equals(localId)))
        .write(
      drift_db.PendingTransactionsCompanion(
        status: Value(PendingTransactionStatus.synced.storageValue),
        syncedAt: Value(DateTime.now()),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> markFailed(int localId, String error) async {
    await (_db.update(_db.pendingTransactions)
          ..where((t) => t.id.equals(localId)))
        .write(
      drift_db.PendingTransactionsCompanion(
        status: Value(PendingTransactionStatus.failed.storageValue),
        lastError: Value(error),
      ),
    );
  }

  Future<void> markPending(int localId) async {
    await (_db.update(_db.pendingTransactions)
          ..where((t) => t.id.equals(localId)))
        .write(
      drift_db.PendingTransactionsCompanion(
        status: Value(PendingTransactionStatus.pending.storageValue),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> deleteFailed(int localId) async {
    await (_db.delete(_db.pendingTransactions)
          ..where(
            (t) =>
                t.id.equals(localId) &
                t.status.equals(PendingTransactionStatus.failed.storageValue),
          ))
        .go();
  }

  Future<int> _nextAttemptCount(int localId) async {
    final row = await (_db.select(_db.pendingTransactions)
          ..where((t) => t.id.equals(localId)))
        .getSingleOrNull();
    return (row?.attemptCount ?? 0) + 1;
  }

  Future<List<models.PendingTransaction>> _mapRows(
      List<drift_db.PendingTransaction> rows) async {
    final result = <models.PendingTransaction>[];
    for (final row in rows) {
      final product = await (_db.select(_db.cachedProducts)
            ..where((t) => t.id.equals(row.productId)))
          .getSingleOrNull();
      result.add(
        models.PendingTransaction(
          localId: row.id,
          deviceTxnId: row.deviceTxnId,
          type: PendingTransactionType.fromStorage(row.type),
          productId: row.productId,
          quantity: row.quantity,
          quantityChange: row.quantityChange,
          reason: row.reason,
          createdAt: row.createdAt,
          status: PendingTransactionStatus.fromStorage(row.status),
          attemptCount: row.attemptCount,
          lastError: row.lastError,
          syncedAt: row.syncedAt,
          productName: product?.name,
        ),
      );
    }
    return result;
  }
}
