import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/features/history/presentation/widgets/activity_log_tile.dart';
import 'package:shop_stock_app/models/activity_log.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  ActivityLog log({required String action, Map<String, dynamic>? details}) {
    return ActivityLog(
      id: 'log-1',
      actorId: 'user-1',
      actorName: 'Karim',
      action: action,
      details: details ?? const {'product_name': 'Paracetamol'},
      createdAt: DateTime.utc(2026, 1, 1, 9, 15),
    );
  }

  group('ActivityLogTile', () {
    testWidgets('uses distinct Bengali labels for transaction types',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              ActivityLogTile(log: log(action: 'sale', details: {
                'product_name': 'Paracetamol',
                'quantity': 2,
                'total_amount': 40,
              })),
              ActivityLogTile(log: log(action: 'stock_in', details: {
                'product_name': 'Vitamin C',
                'quantity': 5,
              })),
              ActivityLogTile(log: log(action: 'stock_adjustment', details: {
                'product_name': 'ORS',
                'quantity_change': -1,
                'reason': 'expired',
              })),
            ],
          ),
        ),
      );

      expect(find.text(AppStrings.actionSale), findsOneWidget);
      expect(find.text(AppStrings.actionStockIn), findsOneWidget);
      expect(find.text(AppStrings.actionStockAdjustment), findsOneWidget);
    });
  });
}
