import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/sync/models/pending_transaction_status.dart';
import 'package:shop_stock_app/sync/models/pending_transaction_type.dart';
import 'package:uuid/uuid.dart';

import 'package:shop_stock_app/sync/database/sync_database.dart';
import 'package:shop_stock_app/sync/repositories/pending_transaction_repository.dart';

void main() {
  late SyncDatabase db;
  late PendingTransactionRepository repo;

  setUp(() async {
    db = SyncDatabase(NativeDatabase.memory());
    repo = PendingTransactionRepository(db, uuid: const Uuid());
  });

  tearDown(() async {
    await db.close();
  });

  test('enqueueSale creates pending row with unique device_txn_id', () async {
    final txn = await repo.enqueueSale(productId: 'p1', quantity: 2);
    expect(txn.type, PendingTransactionType.sale);
    expect(txn.productId, 'p1');
    expect(txn.quantity, 2);
    expect(txn.status, PendingTransactionStatus.pending);
    expect(txn.deviceTxnId, isNotEmpty);
  });

  test('fetchFifoPending returns rows in created_at order', () async {
    await repo.enqueueSale(productId: 'p1', quantity: 1);
    await repo.enqueueStockIn(productId: 'p2', quantity: 3);
    final pending = await repo.fetchFifoPending();
    expect(pending.length, 2);
    expect(pending[0].type, PendingTransactionType.sale);
    expect(pending[1].type, PendingTransactionType.stockIn);
  });

  test('markFailed and deleteFailed only affect failed rows', () async {
    final txn = await repo.enqueueSale(productId: 'p1', quantity: 1);
    await repo.markFailed(txn.localId, 'insufficient stock');
    final visible = await repo.fetchVisible();
    expect(visible.single.status, PendingTransactionStatus.failed);
    await repo.deleteFailed(txn.localId);
    expect(await repo.fetchVisible(), isEmpty);
  });

  test('markSynced removes row from actionable count', () async {
    final txn = await repo.enqueueSale(productId: 'p1', quantity: 1);
    expect(await repo.countActionable(), 1);
    await repo.markSynced(txn.localId);
    expect(await repo.countActionable(), 0);
  });
}
