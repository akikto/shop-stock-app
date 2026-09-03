import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/sync_database.dart';
import 'providers/sync_providers.dart';
import 'services/connectivity_service.dart';
import 'services/sync_coordinator.dart';

/// Opens the local sync database and starts connectivity-driven sync.
class SyncBootstrap {
  SyncBootstrap._();

  static SyncDatabase? _database;
  static ConnectivityService? _connectivity;
  static SyncCoordinator? _coordinator;
  static bool isInitialized = false;

  /// Builds a [ProviderContainer] with sync overrides supplied at construction.
  static Future<ProviderContainer> createContainer() async {
    _database = await SyncDatabase.open();
    _connectivity = ConnectivityService();
    await _connectivity!.start();

    final container = ProviderContainer(
      overrides: [
        syncDatabaseProvider.overrideWithValue(_database!),
        connectivityServiceProvider.overrideWithValue(_connectivity!),
        syncCoordinatorProvider.overrideWith((ref) {
          return SyncCoordinator(
            connectivity: _connectivity!,
            engine: ref.watch(syncEngineProvider),
            onSyncStateChanged: (isSyncing, error) {
              final ctrl = ref.read(syncControllerProvider.notifier);
              if (isSyncing) {
                ctrl.setSyncing();
              } else if (error != null) {
                ctrl.reportError(error);
              } else {
                ctrl.reportSuccess();
              }
            },
          );
        }),
        syncControllerProvider.overrideWith(
          (ref) => SyncController(ref.watch(syncCoordinatorProvider)),
        ),
      ],
    );

    _coordinator = container.read(syncCoordinatorProvider);
    _coordinator!.start();
    isInitialized = true;
    return container;
  }

  static Future<void> dispose() async {
    await _coordinator?.dispose();
    await _connectivity?.dispose();
    await _database?.close();
    _coordinator = null;
    _connectivity = null;
    _database = null;
    isInitialized = false;
  }
}
