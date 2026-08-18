import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product.dart';
import '../../../repositories/reports_repository.dart';
import '../../../services/report_calculations.dart';
import '../../products/providers/product_providers.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return SupabaseReportsRepository();
});

enum ReportRangePreset { today, last7Days, last30Days }

class ReportDateRange {
  const ReportDateRange({required this.start, required this.end, required this.preset});
  final DateTime start;
  final DateTime end;
  final ReportRangePreset preset;

  static ReportDateRange forPreset(ReportRangePreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case ReportRangePreset.today:
        return ReportDateRange(start: today, end: today, preset: preset);
      case ReportRangePreset.last7Days:
        return ReportDateRange(start: today.subtract(const Duration(days: 6)), end: today, preset: preset);
      case ReportRangePreset.last30Days:
        return ReportDateRange(start: today.subtract(const Duration(days: 29)), end: today, preset: preset);
    }
  }
}

final reportDateRangeProvider = StateProvider<ReportDateRange>((ref) {
  return ReportDateRange.forPreset(ReportRangePreset.today);
});

final dailySalesProvider = FutureProvider.autoDispose<List<DailySalesPoint>>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(reportsRepositoryProvider).fetchDailySales(start: range.start, end: range.end);
});

final staffWiseSalesProvider = FutureProvider.autoDispose<List<StaffSalesSummary>>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(reportsRepositoryProvider).fetchStaffWiseSales(start: range.start, end: range.end);
});

final productWiseSalesProvider = FutureProvider.autoDispose<List<ProductSalesSummary>>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(reportsRepositoryProvider).fetchProductWiseSales(start: range.start, end: range.end);
});

final stockMovementProvider = FutureProvider.autoDispose<List<StockMovementSummary>>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(reportsRepositoryProvider).fetchStockMovement(start: range.start, end: range.end);
});

/// Low-stock is current state, not date-ranged. Visible to every
/// role — `products` is readable by all authenticated users (see
/// migration 0003), and knowing what's running low is useful to
/// staff too, not just Owner/Manager.
final lowStockProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  // Small shop catalog — fetch a generous page of active products and
  // filter client-side rather than adding a new server-side endpoint
  // for what's fundamentally a display filter over existing data.
  final products = await repo.fetchProducts(activeOnly: true, limit: 200);
  return products.where((p) => p.isLowStock).toList();
});
