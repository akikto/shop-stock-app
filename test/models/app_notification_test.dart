import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/models/app_notification.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('parses unread notification', () {
      final n = AppNotification.fromJson({
        'id': 'n1',
        'type': 'sale',
        'message': 'Sale recorded',
        'read': false,
        'created_at': '2026-01-15T10:30:00Z',
      });

      expect(n.id, 'n1');
      expect(n.type, 'sale');
      expect(n.message, 'Sale recorded');
      expect(n.read, isFalse);
      expect(n.createdAt, DateTime.parse('2026-01-15T10:30:00Z'));
    });

    test('defaults read to false when null', () {
      final n = AppNotification.fromJson({
        'id': 'n2',
        'type': 'low_stock',
        'message': 'Low stock',
        'created_at': '2026-01-15T10:30:00Z',
      });

      expect(n.read, isFalse);
    });

    test('parses read notification', () {
      final n = AppNotification.fromJson({
        'id': 'n3',
        'type': 'stock_in',
        'message': 'Stock in',
        'read': true,
        'created_at': '2026-01-15T10:30:00Z',
      });

      expect(n.read, isTrue);
    });
  });
}
