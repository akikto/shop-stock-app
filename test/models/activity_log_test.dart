import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/models/activity_log.dart';

void main() {
  group('ActivityLog', () {
    test('fromJson maps all fields correctly', () {
      final json = {
        'id': 'log-1',
        'actor_id': 'user-1',
        'action': 'sale',
        'reference_table': 'sales',
        'reference_id': 'sale-1',
        'details': {'product_name': 'Paracetamol', 'quantity': 3},
        'created_at': '2026-08-20T10:00:00Z',
      };

      final log = ActivityLog.fromJson(json);

      expect(log.id, 'log-1');
      expect(log.actorId, 'user-1');
      expect(log.action, 'sale');
      expect(log.referenceTable, 'sales');
      expect(log.referenceId, 'sale-1');
      expect(log.details, isA<Map<String, dynamic>>());
      expect(log.details!['product_name'], 'Paracetamol');
      expect(log.createdAt, DateTime.utc(2026, 8, 20, 10));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'log-2',
        'actor_id': 'user-1',
        'action': 'stock_in',
        'reference_table': null,
        'reference_id': null,
        'details': {},
        'created_at': '2026-08-20T10:00:00Z',
      };

      final log = ActivityLog.fromJson(json);

      expect(log.referenceTable, isNull);
      expect(log.referenceId, isNull);
    });
  });
}
