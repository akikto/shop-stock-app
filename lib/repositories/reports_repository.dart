import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_stats.dart';
import '../models/product_sales_row.dart';
import '../models/staff_sales_row.dart';
import '../services/supabase_service.dart';

class ReportsException implements Exception {
  ReportsException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class ReportsRepository {
  Future<DashboardStats> fetchDashboardStats(
      {required DateTime from, required DateTime to});
  Future<List<StaffSalesRow>> fetchStaffSalesReport(
      {required DateTime from, required DateTime to});
  Future<List<ProductSalesRow>> fetchProductSalesReport(
      {required DateTime from, required DateTime to});
}

class SupabaseReportsRepository implements ReportsRepository {
  SupabaseReportsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  @override
  Future<DashboardStats> fetchDashboardStats(
      {required DateTime from, required DateTime to}) async {
    try {
      final result = await _client.rpc('get_dashboard_stats', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
      });
      return DashboardStats.fromJson(Map<String, dynamic>.from(result as Map));
    } on PostgrestException catch (e) {
      throw ReportsException(
          e.message.isNotEmpty ? e.message : 'Could not load dashboard.');
    } catch (_) {
      throw ReportsException('Could not load dashboard.');
    }
  }

  @override
  Future<List<StaffSalesRow>> fetchStaffSalesReport(
      {required DateTime from, required DateTime to}) async {
    try {
      final result = await _client.rpc('get_staff_sales_report', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
      });
      return (result as List)
          .map((row) =>
              StaffSalesRow.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw ReportsException(
          e.message.isNotEmpty ? e.message : 'Could not load staff report.');
    } catch (_) {
      throw ReportsException('Could not load staff report.');
    }
  }

  @override
  Future<List<ProductSalesRow>> fetchProductSalesReport(
      {required DateTime from, required DateTime to}) async {
    try {
      final result = await _client.rpc('get_product_sales_report', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
      });
      return (result as List)
          .map((row) =>
              ProductSalesRow.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw ReportsException(
          e.message.isNotEmpty ? e.message : 'Could not load product report.');
    } catch (_) {
      throw ReportsException('Could not load product report.');
    }
  }
}
