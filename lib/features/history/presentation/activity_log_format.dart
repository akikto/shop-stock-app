import '../../../core/localization/app_strings.dart';
import '../../../models/activity_log.dart';

/// Bengali-friendly formatting for activity log rows.
class ActivityLogFormat {
  const ActivityLogFormat._();

  static String dateTime(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  static String? quantityLine(ActivityLog log) {
    final quantity = log.quantity;
    if (quantity != null) {
      return '${AppStrings.quantity}: $quantity';
    }

    final change = log.quantityChange;
    if (change != null) {
      final prefix = change > 0 ? AppStrings.increaseStock : AppStrings.decreaseStock;
      final amount = change.abs();
      return '${AppStrings.quantity}: $prefix $amount';
    }

    return null;
  }

  static String? saleAmountLine(ActivityLog log) {
    final amount = log.saleAmount;
    if (amount == null) return null;
    return '${AppStrings.total}: ${AppStrings.currencySymbol}$amount';
  }

  static String? reasonLine(ActivityLog log) {
    final reason = log.reason;
    if (reason == null || reason.isEmpty) return null;
    return '${AppStrings.reason}: $reason';
  }

  static String? actorLine(ActivityLog log) {
    final name = log.actorName;
    if (name == null || name.isEmpty) return null;
    return '${AppStrings.performedBy}: $name';
  }
}
