import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/repositories/transaction_repository.dart';
import 'package:shop_stock_app/sync/database/sync_database_io.dart';
import 'package:shop_stock_app/sync/models/cached_product.dart' as models;
import 'package:shop_stock_app/sync/models/transaction_write_result.dart';
import 'package:shop_stock_app/sync/repositories/offline_aware_transaction_repository.dart';
import 'package:shop_stock_app/sync/repositories/pending_transaction_repository.dart';
import 'package:shop_stock_app/sync/repositories/product_cache_repository.dart';
import 'package:shop_stock_app/sync/services/connectivity_service.dart';
import 'package:shop_stock_app/sync/sync_bootstrap.dart';
import 'package:uuid/uuid.dart';

class FakeConnectivityService extends ConnectivityService {
  FakeConnectivityService({required this.online}) : super();

  bool online;

  @override
  bool get isOnline => online;

  @override
  Future<void> start() async {}
}

class FakeRemoteRepository implements TransactionRepository {
  int saleCalls = 0;
  String? lastDeviceTxnId;

  @override
  Future<TransactionWriteResult> recordSale({
    required String productId,
    required num quantity,
    String? deviceTxnId,
  }) async {
    saleCalls++;
    lastDeviceTxnId = deviceTxnId;
    return TransactionWriteResult.synced;
  }

  @override
  Future<TransactionWriteResult> recordStockIn({
    required String productId,
    required num quantity,
    String? deviceTxnId,
  }) async =>
      TransactionWriteResult.synced;

  @override
  Future<TransactionWriteResult> recordAdjustment({
    required String productId,
    required num quantityChange,
    required String reason,
    String? deviceTxnId,
  }) async =>
      TransactionWriteResult.synced;
}

void main() {
  late SyncDatabase db;
  late PendingTransactionRepository pendingRepo;
  late ProductCacheRepository cacheRepo;
  late FakeConnectivityService connectivity;
  late FakeRemoteRepository remote;

  setUp(() async {
    SyncBootstrap.isInitialized = true;
    db = SyncDatabase(NativeDatabase.memory());
    pendingRepo = PendingTransactionRepository(db, uuid: const Uuid());
    cacheRepo = ProductCacheRepository(db);
    connectivity = FakeConnectivityService(online: false);
    remote = FakeRemoteRepository();
    await cacheRepo.replaceAll([
      models.CachedProduct(
        id: 'p1',
        name: 'Item',
        salePrice: 10,
        currentStock: 10,
        lowStockLimit: 2,
        isActive: true,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    ]);
  });

  tearDown(() async {
    SyncBootstrap.isInitialized = false;
    await db.close();
  });

  test('offline queues sale and updates cached stock optimistically', () async {
    final repo = OfflineAwareTransactionRepository(
      connectivity: connectivity,
      remote: remote,
      pendingRepo: pendingRepo,
      cacheRepo: cacheRepo,
      uuid: const Uuid(),
    );

    final result = await repo.recordSale(productId: 'p1', quantity: 3);
    expect(result, TransactionWriteResult.queuedLocally);
    expect(remote.saleCalls, 0);
    expect(await pendingRepo.countActionable(), 1);
    final cached = await cacheRepo.getById('p1');
    expect(cached!.currentStock, 7);
  });

  test('online uses remote with stable deviceTxnId when supplied', () async {
    connectivity.online = true;
    final repo = OfflineAwareTransactionRepository(
      connectivity: connectivity,
      remote: remote,
      pendingRepo: pendingRepo,
      cacheRepo: cacheRepo,
      uuid: const Uuid(),
    );

    await repo.recordSale(
        productId: 'p1', quantity: 1, deviceTxnId: 'fixed-id');
    expect(remote.saleCalls, 1);
    expect(remote.lastDeviceTxnId, 'fixed-id');
  });
}
