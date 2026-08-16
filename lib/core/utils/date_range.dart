/// Helpers for dashboard/report date ranges in local time.
class DateRange {
  const DateRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  /// Start of [day] (local) through start of next day.
  factory DateRange.forDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return DateRange(from: start, to: start.add(const Duration(days: 1)));
  }

  /// Today in local time.
  factory DateRange.today() => DateRange.forDay(DateTime.now());

  /// Last 7 days including today.
  factory DateRange.last7Days() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    return DateRange(from: start, to: DateRange.today().to);
  }
}
