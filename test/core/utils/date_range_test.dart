import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/utils/date_range.dart';

void main() {
  group('DateRange', () {
    test('today spans one local day', () {
      final range = DateRange.today();
      expect(range.to.difference(range.from).inHours, 24);
      expect(range.isToday(), isTrue);
      expect(range.isLast7Days(), isFalse);
      expect(range.isCustom(), isFalse);
    });

    test('last7Days spans 7 days', () {
      final range = DateRange.last7Days();
      expect(range.to.difference(range.from).inDays, 7);
      expect(range.isLast7Days(), isTrue);
      expect(range.isToday(), isFalse);
    });

    test('custom normalizes inclusive local days to half-open interval', () {
      final range = DateRange.custom(
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 3),
      );
      expect(range.from, DateTime(2026, 3, 1));
      expect(range.to, DateTime(2026, 3, 4));
      expect(range.isCustom(), isTrue);
    });

    test('custom throws on invalid range', () {
      expect(
        () => DateRange.custom(DateTime(2026, 3, 5), DateTime(2026, 3, 1)),
        throwsA(isA<InvalidDateRangeException>()),
      );
      expect(
        () => DateRange.custom(DateTime(2026, 3, 1), DateTime(2026, 3, 1)),
        returnsNormally,
      );
    });

    test('equality and hashCode use from/to', () {
      final a = DateRange.forDay(DateTime(2026, 1, 15));
      final b = DateRange.forDay(DateTime(2026, 1, 15));
      final c = DateRange.forDay(DateTime(2026, 1, 16));

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('toUtcRpcParams uses UTC ISO strings', () {
      final range = DateRange.forDay(DateTime(2026, 6, 10));
      final params = range.toUtcRpcParams();
      expect(params['p_from'], contains('2026-06-10'));
      expect(params['p_to'], isNotEmpty);
      expect(DateTime.parse(params['p_from']!).isUtc, isTrue);
      expect(DateTime.parse(params['p_to']!).isUtc, isTrue);
    });
  });
}
