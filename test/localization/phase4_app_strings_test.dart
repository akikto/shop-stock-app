import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';

bool _containsBengali(String value) {
  return value.runes.any((rune) => rune >= 0x0980 && rune <= 0x09FF);
}

void main() {
  group('Phase 4 AppStrings', () {
    final keys = <String, String>{
      'loadingDashboard': AppStrings.loadingDashboard,
      'activeProductCount': AppStrings.activeProductCount,
      'quickActionNewSale': AppStrings.quickActionNewSale,
      'quickActionStockIn': AppStrings.quickActionStockIn,
      'quickActionHistory': AppStrings.quickActionHistory,
      'customDateRange': AppStrings.customDateRange,
      'pickDateRange': AppStrings.pickDateRange,
      'invalidDateRange': AppStrings.invalidDateRange,
      'loadingReports': AppStrings.loadingReports,
      'dashboardLoadFailed': AppStrings.dashboardLoadFailed,
      'staffReportLoadFailed': AppStrings.staffReportLoadFailed,
      'productReportLoadFailed': AppStrings.productReportLoadFailed,
      'stockMovementReportLoadFailed': AppStrings.stockMovementReportLoadFailed,
      'reportSaleCount': AppStrings.reportSaleCount(3),
      'reportProductSubtitle': AppStrings.reportProductSubtitle(2, 5),
    };

    for (final entry in keys.entries) {
      test('${entry.key} is non-empty Bengali', () {
        expect(entry.value.trim(), isNotEmpty);
        expect(_containsBengali(entry.value), isTrue,
            reason: '${entry.key} should use Bengali script');
      });
    }
  });
}
