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

  /// Builds a [ProviderContainer] with all sync overrides applied at creation.
  ///
  /// Riverpod does not allow adding overrides via [ProviderContainer.updateOverrides]
  /// on an empty container — overrides must be supplied at construction time.
  static Future<ProviderContainer> createContainer() async {
    _database = await SyncDatabase.open();
    _connectivity = ConnectivityService();
    await _connectivity!.start();

    final setupContainer = ProviderContainer(
      overrides: [
        syncDatabaseProvider.overrideWithValue(_database!),
        connectivityServiceProvider.overrideWithValue(_connectivity!),
      ],
    );
    final engine = setupContainer.read(syncEngineProvider);
    setupContainer.dispose();

    late SyncController syncController;
    _coordinator = SyncCoordinator(
      connectivity: _connectivity!,
      engine: engine,
      onSyncStateChanged: (isSyncing, error) {
        if (isSyncing) {
          syncController.setSyncing();
        } else if (error != null) {
          syncController.reportError(error);
        } else {
          syncController.reportSuccess();
        }
      },
    );

    final container = ProviderContainer(
      overrides: [
        syncDatabaseProvider.overrideWithValue(_database!),
        connectivityServiceProvider.overrideWithValue(_connectivity!),
        syncCoordinatorProvider.overrideWithValue(_coordinator!),
        syncControllerProvider.overrideWith((ref) {
          syncController = SyncController(_coordinator!);
          return syncController;
        }),
      ],
    );

    // Ensure controller exists before coordinator schedules sync work.
    container.read(syncControllerProvider);

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
