/// Helpers for dashboard/report date ranges in local time.
class DateRange {
  const DateRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  /// Start of [day] (local) through start of next day (exclusive end).
  factory DateRange.forDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return DateRange(from: start, to: start.add(const Duration(days: 1)));
  }

  /// Today in local time.
  factory DateRange.today() => DateRange.forDay(DateTime.now());

  /// Last 7 days including today.
  factory DateRange.last7Days() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 6));
    return DateRange(from: start, to: DateRange.today().to);
  }

  /// Inclusive local start day through inclusive local end day.
  ///
  /// [from] and [to] are normalized to local midnight; [to] is stored
  /// as the start of the day after the inclusive end (half-open interval).
  factory DateRange.custom(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final inclusiveEnd = DateTime(to.year, to.month, to.day);
    final endExclusive = inclusiveEnd.add(const Duration(days: 1));
    if (!start.isBefore(endExclusive)) {
      throw InvalidDateRangeException();
    }
    return DateRange(from: start, to: endExclusive);
  }

  /// Whether this range matches [DateRange.today()] for the current local day.
  bool isToday() {
    final today = DateRange.today();
    return from == today.from && to == today.to;
  }

  /// Whether this range matches [DateRange.last7Days()].
  bool isLast7Days() {
    final last7 = DateRange.last7Days();
    return from == last7.from && to == last7.to;
  }

  /// True when neither [isToday] nor [isLast7Days].
  bool isCustom() => !isToday() && !isLast7Days();

  /// UTC ISO-8601 strings for RPC parameters.
  Map<String, String> toUtcRpcParams() => {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange && from == other.from && to == other.to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Thrown by [DateRange.custom] when the inclusive end precedes the start.
class InvalidDateRangeException implements Exception {
  @override
  String toString() => 'InvalidDateRangeException';
}
