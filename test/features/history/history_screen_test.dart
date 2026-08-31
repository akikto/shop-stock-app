import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/features/history/presentation/history_screen.dart';
import 'package:shop_stock_app/features/history/providers/history_providers.dart';
import 'package:shop_stock_app/models/activity_log.dart';
import 'package:shop_stock_app/repositories/activity_log_repository.dart';

class FakeActivityLogRepository implements ActivityLogRepository {
  FakeActivityLogRepository(this.logs, {this.delay, this.shouldFail = false});

  final List<ActivityLog> logs;
  final Duration? delay;
  bool shouldFail;

  @override
  Future<List<ActivityLog>> fetchActivityLogs(
      {int limit = 20, int offset = 0}) async {
    if (delay != null) await Future<void>.delayed(delay!);
    if (shouldFail) {
      throw ActivityLogException(AppStrings.historyLoadFailed);
    }
    if (offset >= logs.length) return [];
    final end = (offset + limit).clamp(0, logs.length);
    return logs.sublist(offset, end);
  }
}

ActivityLog sampleLog({
  required String action,
  String? productName,
  num? quantity,
  num? quantityChange,
  num? totalAmount,
  String? reason,
  String? actorName,
}) {
  return ActivityLog(
    id: 'log-1',
    actorId: 'user-1',
    actorName: actorName,
    action: action,
    details: {
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (quantityChange != null) 'quantity_change': quantityChange,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (reason != null) 'reason': reason,
    },
    createdAt: DateTime.utc(2026, 1, 1, 10, 30),
  );
}

Widget _wrap(Widget child, ActivityLogRepository repo) {
  return ProviderScope(
    overrides: [
      activityLogRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(home: child),
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Expected widget not found: $finder');
}

void main() {
  group('HistoryScreen', () {
    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HistoryScreen(),
          FakeActivityLogRepository(
            [],
            delay: const Duration(seconds: 5),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.loadingHistory), findsOneWidget);
    });

    testWidgets('shows empty state when no activity exists', (tester) async {
      await tester.pumpWidget(
        _wrap(const HistoryScreen(), FakeActivityLogRepository([])),
      );
      await _pumpUntilFound(tester, find.text(AppStrings.noHistoryFound));

      expect(find.text(AppStrings.noHistoryFound), findsOneWidget);
    });

    testWidgets('shows error state with Bengali retry label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HistoryScreen(),
          FakeActivityLogRepository([], shouldFail: true),
        ),
      );
      await _pumpUntilFound(tester, find.text(AppStrings.historyLoadFailed));

      expect(find.text(AppStrings.historyLoadFailed), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
    });

    testWidgets('renders sale, stock in, and adjustment with Bengali labels',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HistoryScreen(),
          FakeActivityLogRepository([
            sampleLog(
              action: 'sale',
              productName: 'Paracetamol',
              quantity: 2,
              totalAmount: 40,
              actorName: 'Karim',
            ),
            sampleLog(
              action: 'stock_in',
              productName: 'Vitamin C',
              quantity: 10,
            ),
            sampleLog(
              action: 'stock_adjustment',
              productName: 'ORS',
              quantityChange: -1,
              reason: 'expired',
            ),
          ]),
        ),
      );
      await _pumpUntilFound(tester, find.text(AppStrings.actionSale));

      expect(find.text(AppStrings.actionSale), findsOneWidget);
      expect(find.text(AppStrings.actionStockIn), findsOneWidget);
      expect(find.text(AppStrings.actionStockAdjustment), findsOneWidget);
      expect(find.text('Paracetamol'), findsOneWidget);
      expect(
        find.text('${AppStrings.performedBy}: Karim'),
        findsOneWidget,
      );
      expect(
        find.text('${AppStrings.total}: ${AppStrings.currencySymbol}40'),
        findsOneWidget,
      );
      expect(
        find.text('${AppStrings.reason}: expired'),
        findsOneWidget,
      );
    });
  });
}
