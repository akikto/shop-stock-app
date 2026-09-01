import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_providers.dart';

/// Coalesces rapid dashboard invalidations (e.g. product Realtime bursts)
/// so RPC errors can surface instead of staying stuck on loading.
class DebouncedDashboardRefresh {
  DebouncedDashboardRefresh(this._ref);

  final Ref _ref;
  Timer? _timer;

  static const _delay = Duration(milliseconds: 1200);

  void schedule() {
    _timer?.cancel();
    _timer = Timer(_delay, _invalidateNow);
  }

  void _invalidateNow() {
    final range = _ref.read(dashboardHomeRangeProvider);
    _ref.invalidate(dashboardStatsProvider(range));
    _ref.invalidate(shopActiveProductCountProvider);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

final debouncedDashboardRefreshProvider =
    Provider.autoDispose<DebouncedDashboardRefresh>((ref) {
  final refresh = DebouncedDashboardRefresh(ref);
  ref.onDispose(refresh.dispose);
  return refresh;
});
