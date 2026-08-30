import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/features/history/providers/history_providers.dart';
import 'package:shop_stock_app/models/activity_log.dart';
import 'package:shop_stock_app/repositories/activity_log_repository.dart';

class FakeActivityLogRepository implements ActivityLogRepository {
  FakeActivityLogRepository(this.logs, {this.onFetch});

  final List<ActivityLog> logs;
  final void Function({required int limit, required int offset})? onFetch;
  bool shouldFail = false;

  @override
  Future<List<ActivityLog>> fetchActivityLogs(
      {int limit = 20, int offset = 0}) async {
    onFetch?.call(limit: limit, offset: offset);
    if (shouldFail) {
      throw ActivityLogException(AppStrings.historyLoadFailed);
    }
    if (offset >= logs.length) return [];
    final end = (offset + limit).clamp(0, logs.length);
    return logs.sublist(offset, end);
  }
}

ActivityLog sampleLog(String id, {String actorId = 'user-1'}) {
  return ActivityLog(
    id: id,
    actorId: actorId,
    action: 'sale',
    details: const {'product_name': 'Paracetamol', 'quantity': 1},
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

Future<void> waitForHistoryState(
  HistoryListController controller,
  bool Function(HistoryListState state) isReady,
) async {
  for (var i = 0; i < 200; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (isReady(controller.state)) return;
  }
  fail('HistoryListController did not reach the expected state');
}

void main() {
  group('HistoryListController', () {
    test('loads the first page on creation', () async {
      final repo = FakeActivityLogRepository([sampleLog('1')]);
      final controller = HistoryListController(repo);

      await waitForHistoryState(
        controller,
        (state) => !state.isLoading && state.logs.length == 1,
      );

      expect(controller.state.error, isNull);
    });

    test('exposes empty state when repository returns no rows', () async {
      final controller = HistoryListController(FakeActivityLogRepository([]));
      await waitForHistoryState(
        controller,
        (state) => !state.isLoading && state.logs.isEmpty && state.error == null,
      );
    });

    test('exposes error state when the repository fails', () async {
      final repo = FakeActivityLogRepository([])
        ..shouldFail = true;
      final controller = HistoryListController(repo);
      await waitForHistoryState(
        controller,
        (state) => !state.isLoading && state.error != null,
      );

      expect(controller.state.error, AppStrings.historyLoadFailed);
    });

    test('refresh clears a previous error and reloads data', () async {
      final repo = FakeActivityLogRepository([sampleLog('1')])
        ..shouldFail = true;
      final controller = HistoryListController(repo);
      await waitForHistoryState(
        controller,
        (state) => !state.isLoading && state.error != null,
      );

      repo.shouldFail = false;
      await controller.refresh();
      await waitForHistoryState(
        controller,
        (state) => !state.isLoading && state.logs.length == 1 && state.error == null,
      );
    });

    test('loadMore appends the next page and stops when fewer than page size',
        () async {
      final repo = FakeActivityLogRepository(
        List.generate(25, (i) => sampleLog('$i')),
      );
      final controller = HistoryListController(repo);
      await waitForHistoryState(
        controller,
        (state) => !state.isLoading && state.logs.length == 20,
      );

      expect(controller.state.hasMore, isTrue);

      await controller.loadMore();
      await waitForHistoryState(
        controller,
        (state) => !state.isLoadingMore && state.logs.length == 25,
      );

      expect(controller.state.hasMore, isFalse);
    });
  });
}
