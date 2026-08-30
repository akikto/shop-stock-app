import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/history/providers/history_providers.dart';
import '../../features/home/providers/dashboard_providers.dart';
import '../../features/home/providers/notification_providers.dart';
import '../../features/products/providers/product_providers.dart';
import '../../features/settings/providers/staff_providers.dart'
    show syncConflictRepositoryProvider, syncConflictsProvider;
import '../../repositories/transaction_repository.dart';
import '../database/sync_database.dart';
import '../models/pending_transaction.dart' as models;
import '../models/sync_state.dart';
import '../repositories/offline_aware_transaction_repository.dart';
import '../repositories/pending_transaction_repository.dart';
import '../repositories/product_cache_repository.dart';
import '../services/connectivity_service.dart';
import '../services/sync_coordinator.dart';
import '../services/sync_engine.dart';
import '../sync_bootstrap.dart';

final syncDatabaseProvider = Provider<SyncDatabase>((ref) {
  throw UnimplementedError('SyncDatabase must be overridden at bootstrap');
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  throw UnimplementedError(
      'ConnectivityService must be overridden at bootstrap');
});

final productCacheRepositoryProvider = Provider<ProductCacheRepository>((ref) {
  return ProductCacheRepository(ref.watch(syncDatabaseProvider));
});

final pendingTransactionRepositoryProvider =
    Provider<PendingTransactionRepository>((ref) {
  return PendingTransactionRepository(ref.watch(syncDatabaseProvider));
});

final supabaseTransactionRepositoryProvider =
    Provider<SupabaseTransactionRepository>((ref) {
  return SupabaseTransactionRepository();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    pendingRepo: ref.watch(pendingTransactionRepositoryProvider),
    cacheRepo: ref.watch(productCacheRepositoryProvider),
    productRepo: ref.watch(productRepositoryProvider),
    remoteRepo: ref.watch(supabaseTransactionRepositoryProvider),
    conflictRepo: ref.watch(syncConflictRepositoryProvider),
    onInvalidate: () {
      ref.invalidate(productListControllerProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(unreadNotificationCountProvider);
      ref.invalidate(historyListControllerProvider);
      ref.invalidate(pendingTransactionCountProvider);
      ref.invalidate(pendingTransactionsListProvider);
      ref.invalidate(syncConflictsProvider);
    },
  );
});

final offlineAwareTransactionRepositoryProvider =
    Provider<TransactionRepository>((ref) {
  if (kIsWeb || !SyncBootstrap.isInitialized) {
    return ref.watch(supabaseTransactionRepositoryProvider);
  }
  return OfflineAwareTransactionRepository(
    connectivity: ref.watch(connectivityServiceProvider),
    remote: ref.watch(supabaseTransactionRepositoryProvider),
    pendingRepo: ref.watch(pendingTransactionRepositoryProvider),
    cacheRepo: ref.watch(productCacheRepositoryProvider),
  );
});

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onlineStream;
});

final pendingTransactionCountProvider = FutureProvider<int>((ref) async {
  if (!SyncBootstrap.isInitialized) return 0;
  ref.watch(pendingTransactionsListProvider);
  return ref.watch(pendingTransactionRepositoryProvider).countActionable();
});

final pendingTransactionsListProvider =
    FutureProvider<List<models.PendingTransaction>>((ref) async {
  if (!SyncBootstrap.isInitialized) return [];
  return ref.watch(pendingTransactionRepositoryProvider).fetchVisible();
});

class SyncController extends StateNotifier<SyncState> {
  SyncController(this._coordinator) : super(const SyncState());

  final SyncCoordinator _coordinator;

  void setSyncing() {
    state = state.copyWith(isSyncing: true, clearLastError: true);
  }

  Future<void> requestSync({bool refreshCache = false}) async {
    await _coordinator.requestSync(refreshCache: refreshCache);
  }

  void reportError(String? error) {
    state = state.copyWith(isSyncing: false, lastError: error);
  }

  void reportSuccess() {
    state = state.copyWith(
      isSyncing: false,
      clearLastError: true,
      lastSuccessfulSyncAt: DateTime.now(),
    );
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  throw UnimplementedError('SyncController must be overridden at bootstrap');
});

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  throw UnimplementedError('SyncCoordinator must be overridden at bootstrap');
});
