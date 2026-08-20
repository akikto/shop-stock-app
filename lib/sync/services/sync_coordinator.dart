import 'dart:async';

import 'package:flutter/widgets.dart';

import 'connectivity_service.dart';
import 'sync_engine.dart';

/// Listens for connectivity / app resume and triggers debounced sync.
class SyncCoordinator with WidgetsBindingObserver {
  SyncCoordinator({
    required ConnectivityService connectivity,
    required SyncEngine engine,
    required void Function(bool isSyncing, String? error) onSyncStateChanged,
  })  : _connectivity = connectivity,
        _engine = engine,
        _onSyncStateChanged = onSyncStateChanged;

  final ConnectivityService _connectivity;
  final SyncEngine _engine;
  final void Function(bool isSyncing, String? error) _onSyncStateChanged;

  StreamSubscription<bool>? _connectivitySub;
  Timer? _debounce;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _connectivitySub = _connectivity.onlineStream.listen((online) {
      if (online) _scheduleSync();
    });
    if (_connectivity.isOnline) {
      _scheduleSync(refreshCache: true);
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _connectivitySub?.cancel();
    _debounce?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _connectivity.isOnline) {
      _scheduleSync();
    }
  }

  Future<void> requestSync({bool refreshCache = false}) async {
    await _runSync(refreshCache: refreshCache);
  }

  void _scheduleSync({bool refreshCache = false}) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _runSync(refreshCache: refreshCache);
    });
  }

  Future<void> _runSync({bool refreshCache = false}) async {
    if (!_connectivity.isOnline) return;
    _onSyncStateChanged(true, null);
    try {
      if (refreshCache) {
        await _engine.refreshProductCache();
      }
      await _engine.processQueue();
      _onSyncStateChanged(false, null);
    } catch (e) {
      _onSyncStateChanged(false, e.toString());
    }
  }
}
