import 'package:flutter/foundation.dart';
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

  static Future<void> initialize(ProviderContainer container) async {
    if (kIsWeb) return;

    _database = await SyncDatabase.open();
    _connectivity = ConnectivityService();
    await _connectivity!.start();

    container.updateOverrides([
      syncDatabaseProvider.overrideWithValue(_database!),
      connectivityServiceProvider.overrideWithValue(_connectivity!),
    ]);

    _coordinator = SyncCoordinator(
      connectivity: _connectivity!,
      engine: container.read(syncEngineProvider),
      onSyncStateChanged: (isSyncing, error) {
        final ctrl = container.read(syncControllerProvider.notifier);
        if (isSyncing) {
          ctrl.setSyncing();
        } else if (error != null) {
          ctrl.reportError(error);
        } else {
          ctrl.reportSuccess();
        }
      },
    );

    container.updateOverrides([
      syncControllerProvider
          .overrideWith((ref) => SyncController(_coordinator!)),
      syncCoordinatorProvider.overrideWithValue(_coordinator!),
    ]);

    _coordinator!.start();
    isInitialized = true;
  }

  static Future<void> dispose() async {
    await _coordinator?.dispose();
    await _connectivity?.dispose();
    await _database?.close();
  }
}
