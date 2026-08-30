import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/models/activity_action.dart';
import 'package:shop_stock_app/models/activity_log.dart';

void main() {
  Map<String, dynamic> baseJson() => {
        'id': 'log-1',
        'actor_id': 'user-1',
        'action': 'sale',
        'reference_table': 'sales',
        'reference_id': 'sale-1',
        'details': {
          'product_name': 'Paracetamol',
          'quantity': 2,
          'total_amount': 20
        },
        'created_at': '2026-01-01T10:00:00Z',
      };

  group('ActivityLog.fromJson', () {
    test('parses a well-formed row', () {
      final log = ActivityLog.fromJson(baseJson());

      expect(log.id, 'log-1');
      expect(log.actorId, 'user-1');
      expect(log.action, 'sale');
      expect(log.referenceTable, 'sales');
      expect(log.details['quantity'], 2);
      expect(log.actorName, isNull,
          reason: 'actor name is resolved separately, not part of the row');
    });

    test('defaults details to an empty map when null', () {
      final json = baseJson()..['details'] = null;
      final log = ActivityLog.fromJson(json);
      expect(log.details, isEmpty);
    });

    test(
        'handles a missing reference_table/reference_id (e.g. future action types)',
        () {
      final json = baseJson()
        ..['reference_table'] = null
        ..['reference_id'] = null;
      final log = ActivityLog.fromJson(json);
      expect(log.referenceTable, isNull);
      expect(log.referenceId, isNull);
    });
  });

  group('ActivityLog.displayProductName', () {
    test('reads product_name from details when present', () {
      final log = ActivityLog.fromJson(baseJson());
      expect(log.displayProductName, 'Paracetamol');
      expect(log.productName, 'Paracetamol');
    });

    test('falls back to name key used by product lifecycle RPCs', () {
      final json = baseJson()
        ..['details'] = {'name': 'Vitamin C'};
      final log = ActivityLog.fromJson(json);
      expect(log.displayProductName, 'Vitamin C');
    });

    test('is null when details has no product name key', () {
      final json = baseJson()..['details'] = {'reason': 'damaged'};
      final log = ActivityLog.fromJson(json);
      expect(log.displayProductName, isNull);
    });
  });

  group('ActivityLog detail getters', () {
    test('reads quantity, quantity_change, total_amount, and reason', () {
      final sale = ActivityLog.fromJson(baseJson());
      expect(sale.quantity, 2);
      expect(sale.quantityChange, isNull);
      expect(sale.saleAmount, 20);
      expect(sale.reason, isNull);

      final adjustment = ActivityLog.fromJson(baseJson()
        ..['action'] = 'stock_adjustment'
        ..['details'] = {
          'product_name': 'Paracetamol',
          'quantity_change': -3,
          'reason': 'expired',
        });
      expect(adjustment.quantity, isNull);
      expect(adjustment.quantityChange, -3);
      expect(adjustment.reason, 'expired');
    });
  });

  group('ActivityLog.copyWithActorName', () {
    test('attaches a resolved actor name without changing other fields', () {
      final log = ActivityLog.fromJson(baseJson());
      final withName = log.copyWithActorName('Karim');

      expect(withName.actorName, 'Karim');
      expect(withName.id, log.id);
      expect(withName.action, log.action);
      expect(withName.details, log.details);
    });
  });

  group('ActivityAction', () {
    test('maps core transaction actions to Bengali labels', () {
      expect(ActivityAction.label(ActivityAction.sale), AppStrings.actionSale);
      expect(
          ActivityAction.label(ActivityAction.stockIn), AppStrings.actionStockIn);
      expect(ActivityAction.label(ActivityAction.stockAdjustment),
          AppStrings.actionStockAdjustment);
    });

    test('maps staff lifecycle actions to Bengali labels', () {
      expect(ActivityAction.label(ActivityAction.userCreated),
          AppStrings.actionUserCreated);
      expect(ActivityAction.label(ActivityAction.userRoleChanged),
          AppStrings.actionUserRoleChanged);
      expect(ActivityAction.label(ActivityAction.userDeactivated),
          AppStrings.actionUserDeactivated);
    });

    test('identifies transaction actions for visual treatment', () {
      expect(ActivityAction.isTransactionAction(ActivityAction.sale), isTrue);
      expect(ActivityAction.isTransactionAction(ActivityAction.stockIn), isTrue);
      expect(ActivityAction.isTransactionAction(ActivityAction.stockAdjustment),
          isTrue);
      expect(
          ActivityAction.isTransactionAction(ActivityAction.productCreated),
          isFalse);
    });

    test('uses distinct accent colors for sale, stock in, and adjustment', () {
      expect(
        ActivityAction.accentColor(ActivityAction.sale),
        isNot(ActivityAction.accentColor(ActivityAction.stockIn)),
      );
      expect(
        ActivityAction.accentColor(ActivityAction.stockIn),
        isNot(ActivityAction.accentColor(ActivityAction.stockAdjustment)),
      );
    });
  });
}
