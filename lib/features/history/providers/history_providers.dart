import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/activity_log.dart';
import '../../../repositories/activity_log_repository.dart';

final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  return SupabaseActivityLogRepository();
});

const int _pageSize = 20;

class HistoryListState {
  const HistoryListState({
    this.logs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<ActivityLog> logs;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  HistoryListState copyWith({
    List<ActivityLog>? logs,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return HistoryListState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives the History screen: initial load, pull-to-refresh, and
/// lazy-loading the next page on scroll. Mirrors
/// ProductListController's shape so the pattern stays consistent
/// across the app.
class HistoryListController extends StateNotifier<HistoryListState> {
  HistoryListController(this._repo) : super(const HistoryListState()) {
    loadFirstPage();
  }

  final ActivityLogRepository _repo;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final logs = await _repo.fetchActivityLogs(offset: 0, limit: _pageSize);
      state = state.copyWith(
          logs: logs, isLoading: false, hasMore: logs.length == _pageSize);
    } on ActivityLogException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final more = await _repo.fetchActivityLogs(
          offset: state.logs.length, limit: _pageSize);
      state = state.copyWith(
        logs: [...state.logs, ...more],
        isLoadingMore: false,
        hasMore: more.length == _pageSize,
      );
    } on ActivityLogException catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.message);
    }
  }

  Future<void> refresh() => loadFirstPage();
}

final historyListControllerProvider =
    StateNotifierProvider<HistoryListController, HistoryListState>((ref) {
  return HistoryListController(ref.watch(activityLogRepositoryProvider));
});
