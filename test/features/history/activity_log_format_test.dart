import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/features/history/presentation/activity_log_format.dart';
import 'package:shop_stock_app/models/activity_log.dart';

void main() {
  ActivityLog log({
    required String action,
    Map<String, dynamic>? details,
    String? actorName,
  }) {
    return ActivityLog(
      id: 'log-1',
      actorId: 'user-1',
      action: action,
      details: details ?? const {},
      createdAt: DateTime.utc(2026, 3, 15, 14, 30),
      actorName: actorName,
    );
  }

  group('ActivityLogFormat', () {
    test('formats local date and time as DD/MM/YYYY HH:MM', () {
      final formatted = ActivityLogFormat.dateTime(
        DateTime.utc(2026, 3, 15, 14, 30),
      );
      expect(formatted, matches(r'^\d{2}/\d{2}/\d{4} \d{2}:\d{2}$'));
    });

    test('builds quantity line for sale and stock in', () {
      final sale = log(
        action: 'sale',
        details: {'quantity': 2},
      );
      expect(ActivityLogFormat.quantityLine(sale), '${AppStrings.quantity}: 2');

      final stockIn = log(
        action: 'stock_in',
        details: {'quantity': 5},
      );
      expect(
          ActivityLogFormat.quantityLine(stockIn), '${AppStrings.quantity}: 5');
    });

    test('builds signed quantity line for adjustments', () {
      final increase = log(
        action: 'stock_adjustment',
        details: {'quantity_change': 4},
      );
      expect(
        ActivityLogFormat.quantityLine(increase),
        '${AppStrings.quantity}: ${AppStrings.increaseStock} 4',
      );

      final decrease = log(
        action: 'stock_adjustment',
        details: {'quantity_change': -2},
      );
      expect(
        ActivityLogFormat.quantityLine(decrease),
        '${AppStrings.quantity}: ${AppStrings.decreaseStock} 2',
      );
    });

    test('builds sale amount line when total_amount is present', () {
      final sale = log(
        action: 'sale',
        details: {'total_amount': 150},
      );
      expect(
        ActivityLogFormat.saleAmountLine(sale),
        '${AppStrings.total}: ${AppStrings.currencySymbol}150',
      );
    });

    test('builds actor and reason lines when available', () {
      final withActor = log(action: 'sale', actorName: 'Karim');
      expect(
        ActivityLogFormat.actorLine(withActor),
        '${AppStrings.performedBy}: Karim',
      );

      final withReason = log(
        action: 'stock_adjustment',
        details: {'reason': 'damaged'},
      );
      expect(
        ActivityLogFormat.reasonLine(withReason),
        '${AppStrings.reason}: damaged',
      );
    });
  });
}
