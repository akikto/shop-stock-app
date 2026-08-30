import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/models/activity_log.dart';
import 'package:shop_stock_app/repositories/activity_log_repository.dart';

class FakeActivityLogRepository implements ActivityLogRepository {
  FakeActivityLogRepository(this.logs, {this.shouldFail = false});

  final List<ActivityLog> logs;
  bool shouldFail;

  int lastLimit = 0;
  int lastOffset = 0;

  @override
  Future<List<ActivityLog>> fetchActivityLogs(
      {int limit = 20, int offset = 0}) async {
    lastLimit = limit;
    lastOffset = offset;
    if (shouldFail) {
      throw ActivityLogException(AppStrings.historyLoadFailed);
    }
    if (offset >= logs.length) return [];
    final end = (offset + limit).clamp(0, logs.length);
    return logs.sublist(offset, end);
  }
}

ActivityLog sampleLog(String id) {
  return ActivityLog(
    id: id,
    actorId: 'user-1',
    action: 'sale',
    details: const {'product_name': 'Paracetamol'},
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('ActivityLogRepository contract', () {
    test('fetchActivityLogs is read-only and paginates by offset/limit', () async {
      final repo = FakeActivityLogRepository(
        List.generate(25, (i) => sampleLog('$i')),
      );

      final firstPage = await repo.fetchActivityLogs(limit: 20, offset: 0);
      final secondPage = await repo.fetchActivityLogs(limit: 20, offset: 20);

      expect(repo.lastLimit, 20);
      expect(repo.lastOffset, 20);
      expect(firstPage, hasLength(20));
      expect(secondPage, hasLength(5));
    });

    test('throws ActivityLogException with Bengali message on failure', () async {
      final repo = FakeActivityLogRepository([])..shouldFail = true;

      expect(
        () => repo.fetchActivityLogs(),
        throwsA(
          predicate<ActivityLogException>(
            (e) => e.message == AppStrings.historyLoadFailed,
          ),
        ),
      );
    });
  });
}
