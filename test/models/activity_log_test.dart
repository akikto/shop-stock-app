import 'package:flutter_test/flutter_test.dart';
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

  group('ActivityLog.productName', () {
    test('reads product_name from details when present', () {
      final log = ActivityLog.fromJson(baseJson());
      expect(log.productName, 'Paracetamol');
    });

    test('is null when details has no product_name key', () {
      final json = baseJson()..['details'] = {'reason': 'damaged'};
      final log = ActivityLog.fromJson(json);
      expect(log.productName, isNull);
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
}
