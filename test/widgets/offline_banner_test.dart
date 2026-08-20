import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/repositories/product_repository.dart';
import 'package:shop_stock_app/repositories/transaction_repository.dart';
import 'package:shop_stock_app/shared/widgets/offline_status_banner.dart';
import 'package:shop_stock_app/sync/database/sync_database_io.dart';
import 'package:shop_stock_app/sync/providers/sync_providers.dart';
import 'package:shop_stock_app/sync/repositories/pending_transaction_repository.dart';
import 'package:shop_stock_app/sync/repositories/product_cache_repository.dart';
import 'package:shop_stock_app/sync/services/connectivity_service.dart';
import 'package:shop_stock_app/sync/services/sync_coordinator.dart';
import 'package:shop_stock_app/sync/services/sync_engine.dart';
import 'package:shop_stock_app/sync/sync_bootstrap.dart';
import 'package:uuid/uuid.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class FakeOfflineConnectivity extends ConnectivityService {
  FakeOfflineConnectivity() : super();

  @override
  bool get isOnline => false;

  @override
  Stream<bool> get onlineStream => Stream.value(false);

  @override
  Future<void> start() async {}
}

SyncCoordinator buildTestCoordinator() {
  final db = SyncDatabase(NativeDatabase.memory());
  final pendingRepo = PendingTransactionRepository(db, uuid: const Uuid());
  final cacheRepo = ProductCacheRepository(db);
  final productRepo = MockProductRepository();
  final remoteRepo = MockTransactionRepository();
  final engine = SyncEngine(
    pendingRepo: pendingRepo,
    cacheRepo: cacheRepo,
    productRepo: productRepo,
    remoteRepo: remoteRepo,
  );
  return SyncCoordinator(
    connectivity: FakeOfflineConnectivity(),
    engine: engine,
    onSyncStateChanged: (_, __) {},
  );
}

void main() {
  testWidgets('offline banner shows Bengali offline mode message',
      (tester) async {
    SyncBootstrap.isInitialized = true;
    final connectivity = FakeOfflineConnectivity();
    final coordinator = buildTestCoordinator();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(connectivity),
          connectivityStatusProvider.overrideWith((ref) => Stream.value(false)),
          syncControllerProvider
              .overrideWith((ref) => SyncController(coordinator)),
          pendingTransactionCountProvider.overrideWith((ref) async => 0),
        ],
        child: const MaterialApp(home: Scaffold(body: OfflineStatusBanner())),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.offlineMode), findsOneWidget);
    SyncBootstrap.isInitialized = false;
    await coordinator.dispose();
  });
}
