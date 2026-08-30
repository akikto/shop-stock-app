import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_stock_app/models/product.dart';
import 'package:shop_stock_app/repositories/product_repository.dart';
import 'package:shop_stock_app/repositories/transaction_repository.dart';
import 'package:shop_stock_app/repositories/sync_conflict_repository.dart';
import 'package:shop_stock_app/sync/database/sync_database_io.dart';
import 'package:shop_stock_app/sync/models/pending_transaction_status.dart';
import 'package:shop_stock_app/sync/models/transaction_write_result.dart';
import 'package:shop_stock_app/sync/repositories/pending_transaction_repository.dart';
import 'package:shop_stock_app/sync/repositories/product_cache_repository.dart';
import 'package:shop_stock_app/sync/services/sync_engine.dart';
import 'package:uuid/uuid.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockSyncConflictRepository extends Mock implements SyncConflictRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late SyncDatabase db;
  late PendingTransactionRepository pendingRepo;
  late ProductCacheRepository cacheRepo;
  late MockProductRepository productRepo;
  late MockTransactionRepository remoteRepo;
  late MockSyncConflictRepository conflictRepo;
  late SyncEngine engine;

  setUp(() async {
    db = SyncDatabase(NativeDatabase.memory());
    pendingRepo = PendingTransactionRepository(db, uuid: const Uuid());
    cacheRepo = ProductCacheRepository(db);
    productRepo = MockProductRepository();
    remoteRepo = MockTransactionRepository();
    conflictRepo = MockSyncConflictRepository();
    engine = SyncEngine(
      pendingRepo: pendingRepo,
      cacheRepo: cacheRepo,
      productRepo: productRepo,
      remoteRepo: remoteRepo,
      conflictRepo: conflictRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('processQueue replays FIFO with stable device_txn_id', () async {
    await pendingRepo.enqueueSale(productId: 'p1', quantity: 1);
    await pendingRepo.enqueueStockIn(productId: 'p2', quantity: 2);

    when(() => remoteRepo.recordSale(
          productId: any(named: 'productId'),
          quantity: any(named: 'quantity'),
          deviceTxnId: any(named: 'deviceTxnId'),
        )).thenAnswer((_) async => TransactionWriteResult.synced);
    when(() => remoteRepo.recordStockIn(
          productId: any(named: 'productId'),
          quantity: any(named: 'quantity'),
          deviceTxnId: any(named: 'deviceTxnId'),
        )).thenAnswer((_) async => TransactionWriteResult.synced);
    when(() => productRepo.fetchProducts(
          search: any(named: 'search'),
          activeOnly: any(named: 'activeOnly'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => []);

    final synced = await engine.processQueue();
    expect(synced, isTrue);
    expect(await pendingRepo.fetchFifoPending(), isEmpty);

    verifyInOrder([
      () => remoteRepo.recordSale(
          productId: 'p1', quantity: 1, deviceTxnId: any(named: 'deviceTxnId')),
      () => remoteRepo.recordStockIn(
          productId: 'p2', quantity: 2, deviceTxnId: any(named: 'deviceTxnId')),
    ]);
  });

  test('insufficient stock marks failed without auto-retry', () async {
    final txn = await pendingRepo.enqueueSale(productId: 'p1', quantity: 99);
    when(() => remoteRepo.recordSale(
          productId: any(named: 'productId'),
          quantity: any(named: 'quantity'),
          deviceTxnId: any(named: 'deviceTxnId'),
        )).thenThrow(TransactionException('Insufficient stock'));
    when(() => conflictRepo.logConflict(
          deviceTxnId: any(named: 'deviceTxnId'),
          action: any(named: 'action'),
          productId: any(named: 'productId'),
          details: any(named: 'details'),
        )).thenAnswer((_) async {});

    await engine.processQueue();
    final row = await pendingRepo.getByLocalId(txn.localId);
    expect(row!.status, PendingTransactionStatus.failed);
    expect(row.lastError!.toLowerCase(), contains('insufficient stock'));
    verify(() => conflictRepo.logConflict(
          deviceTxnId: txn.deviceTxnId,
          action: 'sale',
          productId: 'p1',
          details: any(named: 'details'),
        )).called(1);
  });

  test('network error keeps transaction pending', () async {
    final txn = await pendingRepo.enqueueSale(productId: 'p1', quantity: 1);
    when(() => remoteRepo.recordSale(
          productId: any(named: 'productId'),
          quantity: any(named: 'quantity'),
          deviceTxnId: any(named: 'deviceTxnId'),
        )).thenThrow(Exception('network'));

    await engine.processQueue();
    final row = await pendingRepo.getByLocalId(txn.localId);
    expect(row!.status, PendingTransactionStatus.pending);
  });

  test('duplicate replay success refreshes product cache', () async {
    await pendingRepo.enqueueSale(productId: 'p1', quantity: 1);
    when(() => remoteRepo.recordSale(
          productId: any(named: 'productId'),
          quantity: any(named: 'quantity'),
          deviceTxnId: any(named: 'deviceTxnId'),
        )).thenAnswer((_) async => TransactionWriteResult.synced);
    when(() => productRepo.fetchProducts(
          search: any(named: 'search'),
          activeOnly: any(named: 'activeOnly'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => [
          Product(
            id: 'p1',
            name: 'Test',
            salePrice: 10,
            currentStock: 5,
            lowStockLimit: 1,
            isActive: true,
            createdBy: 'u1',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 2),
          ),
        ]);

    await engine.processQueue();
    final cached = await cacheRepo.fetchActive();
    expect(cached.length, 1);
    expect(cached.first.name, 'Test');
  });
}
