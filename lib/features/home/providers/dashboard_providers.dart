import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_range.dart';
import '../../../models/dashboard_stats.dart';
import '../../../models/product_sales_row.dart';
import '../../../models/staff_sales_row.dart';
import '../../../models/stock_movement_row.dart';
import '../../../models/product.dart';
import '../../../repositories/reports_repository.dart';
import '../../products/providers/product_providers.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return SupabaseReportsRepository();
});

final dashboardStatsProvider = FutureProvider.autoDispose
    .family<DashboardStats, DateRange>((ref, range) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchDashboardStats(from: range.from, to: range.to);
});

final staffSalesReportProvider = FutureProvider.autoDispose
    .family<List<StaffSalesRow>, DateRange>((ref, range) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchStaffSalesReport(from: range.from, to: range.to);
});

final productSalesReportProvider = FutureProvider.autoDispose
    .family<List<ProductSalesRow>, DateRange>((ref, range) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchProductSalesReport(from: range.from, to: range.to);
});

final stockMovementReportProvider = FutureProvider.autoDispose
    .family<List<StockMovementRow>, DateRange>((ref, range) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchStockMovementReport(from: range.from, to: range.to);
});

final lowStockProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.fetchLowStockProducts();
});
