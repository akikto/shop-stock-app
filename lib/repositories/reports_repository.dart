import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/localization/app_strings.dart';
import '../models/dashboard_stats.dart';
import '../models/product_sales_row.dart';
import '../models/staff_sales_row.dart';
import '../models/stock_movement_row.dart';
import '../services/supabase_service.dart';

class ReportsException implements Exception {
  ReportsException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Resolves the user-facing message for report RPC failures.
///
/// Kept as a top-level helper so unit tests can verify Bengali fallbacks
/// without constructing [PostgrestException] instances.
String resolveReportsErrorMessage({
  required String serverMessage,
  required String fallbackMessage,
}) {
  return serverMessage.isNotEmpty ? serverMessage : fallbackMessage;
}

ReportsException _mapReportsException(
  PostgrestException error,
  String fallbackMessage,
) {
  return ReportsException(
    resolveReportsErrorMessage(
      serverMessage: error.message,
      fallbackMessage: fallbackMessage,
    ),
  );
}

abstract class ReportsRepository {
  Future<DashboardStats> fetchDashboardStats(
      {required DateTime from, required DateTime to});
  Future<List<StaffSalesRow>> fetchStaffSalesReport(
      {required DateTime from, required DateTime to});
  Future<List<ProductSalesRow>> fetchProductSalesReport(
      {required DateTime from, required DateTime to});
  Future<List<StockMovementRow>> fetchStockMovementReport(
      {required DateTime from, required DateTime to});
}

class SupabaseReportsRepository implements ReportsRepository {
  SupabaseReportsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Map<String, String> _rpcParams(DateTime from, DateTime to) => {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
      };

  @override
  Future<DashboardStats> fetchDashboardStats(
      {required DateTime from, required DateTime to}) async {
    try {
      final result = await _client.rpc(
        'get_dashboard_stats',
        params: _rpcParams(from, to),
      );
      return DashboardStats.fromJson(Map<String, dynamic>.from(result as Map));
    } on PostgrestException catch (e) {
      throw _mapReportsException(e, AppStrings.dashboardLoadFailed);
    } catch (_) {
      throw ReportsException(AppStrings.dashboardLoadFailed);
    }
  }

  @override
  Future<List<StaffSalesRow>> fetchStaffSalesReport(
      {required DateTime from, required DateTime to}) async {
    try {
      final result = await _client.rpc(
        'get_staff_sales_report',
        params: _rpcParams(from, to),
      );
      return (result as List)
          .map((row) =>
              StaffSalesRow.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw _mapReportsException(e, AppStrings.staffReportLoadFailed);
    } catch (_) {
      throw ReportsException(AppStrings.staffReportLoadFailed);
    }
  }

  @override
  Future<List<ProductSalesRow>> fetchProductSalesReport(
      {required DateTime from, required DateTime to}) async {
    try {
      final result = await _client.rpc(
        'get_product_sales_report',
        params: _rpcParams(from, to),
      );
      return (result as List)
          .map((row) =>
              ProductSalesRow.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw _mapReportsException(e, AppStrings.productReportLoadFailed);
    } catch (_) {
      throw ReportsException(AppStrings.productReportLoadFailed);
    }
  }

  @override
  Future<List<StockMovementRow>> fetchStockMovementReport(
      {required DateTime from, required DateTime to}) async {
    try {
      final result = await _client.rpc(
        'get_stock_movement_report',
        params: _rpcParams(from, to),
      );
      return (result as List)
          .map((row) =>
              StockMovementRow.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw _mapReportsException(e, AppStrings.stockMovementReportLoadFailed);
    } catch (_) {
      throw ReportsException(AppStrings.stockMovementReportLoadFailed);
    }
  }
}
