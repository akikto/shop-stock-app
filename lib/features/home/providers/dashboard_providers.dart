import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_range.dart';
import '../../../models/dashboard_stats.dart';
import '../../../models/product_sales_row.dart';
import '../../../models/staff_sales_row.dart';
import '../../../repositories/reports_repository.dart';

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
