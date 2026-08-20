import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Wraps connectivity_plus for online/offline detection.
///
/// Web builds always report online — offline sync is Android-first and
/// disabled on web preview per Phase 5 scope.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _lastOnline = true;

  Stream<bool> get onlineStream => _controller.stream;

  bool get isOnline => _lastOnline;

  Future<void> start() async {
    if (kIsWeb) {
      _lastOnline = true;
      _controller.add(true);
      return;
    }
    _lastOnline = await _checkOnline();
    _controller.add(_lastOnline);
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final online = _resultsOnline(results);
      if (online != _lastOnline) {
        _lastOnline = online;
        _controller.add(online);
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }

  Future<bool> checkNow() async {
    if (kIsWeb) return true;
    _lastOnline = await _checkOnline();
    _controller.add(_lastOnline);
    return _lastOnline;
  }

  Future<bool> _checkOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _resultsOnline(results);
  }

  bool _resultsOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}
