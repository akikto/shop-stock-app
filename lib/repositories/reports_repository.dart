import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/report_calculations.dart';
import '../services/supabase_service.dart';

class ReportsException implements Exception {
  ReportsException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sole point of contact for report data. RLS already restricts what
/// each caller sees (sales/stock_entries: own rows + manager/owner
/// see all; stock_adjustments: manager/owner only — see migration
/// 0003) — this repository adds no new access rules of its own, it
/// only shapes the query and hands raw rows to the pure aggregation
/// functions in report_calculations.dart.
abstract class ReportsRepository {
  Future<List<DailySalesPoint>> fetchDailySales({required DateTime start, required DateTime end});
  Future<List<StaffSalesSummary>> fetchStaffWiseSales({required DateTime start, required DateTime end});
  Future<List<ProductSalesSummary>> fetchProductWiseSales({required DateTime start, required DateTime end});
  Future<List<StockMovementSummary>> fetchStockMovement({required DateTime start, required DateTime end});
}

class SupabaseReportsRepository implements ReportsRepository {
  SupabaseReportsRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  String _startIso(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String();
  String _endIso(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999).toIso8601String();

  Future<List<Map<String, dynamic>>> _fetchSales(DateTime start, DateTime end, {bool withProductName = false}) async {
    final selectClause = withProductName ? '*, products(name)' : '*';
    final rows = await _client
        .from('sales')
        .select(selectClause)
        .gte('created_at', _startIso(start))
        .lte('created_at', _endIso(end));
    return (rows as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<DailySalesPoint>> fetchDailySales({required DateTime start, required DateTime end}) async {
    try {
      final rows = await _fetchSales(start, end);
      return aggregateDailySales(rows);
    } catch (e) {
      throw ReportsException('Could not load the sales report. Please check your connection.');
    }
  }

  @override
  Future<List<StaffSalesSummary>> fetchStaffWiseSales({required DateTime start, required DateTime end}) async {
    try {
      final rows = await _fetchSales(start, end);
      final Map<String, String> nameById = {};
      try {
        final profiles = await _client.rpc('list_profiles_public') as List;
        for (final p in profiles) {
          final map = p as Map<String, dynamic>;
          nameById[map['id'] as String] = map['name'] as String;
        }
      } catch (_) {
        // Name resolution is a display nicety — fall back to raw ids
        // rather than failing the whole report.
      }
      return aggregateStaffSales(rows, nameById);
    } catch (e) {
      throw ReportsException('Could not load the staff-wise report. Please check your connection.');
    }
  }

  @override
  Future<List<ProductSalesSummary>> fetchProductWiseSales({required DateTime start, required DateTime end}) async {
    try {
      final rows = await _fetchSales(start, end, withProductName: true);
      return aggregateProductSales(rows);
    } catch (e) {
      throw ReportsException('Could not load the product-wise report. Please check your connection.');
    }
  }

  @override
  Future<List<StockMovementSummary>> fetchStockMovement({required DateTime start, required DateTime end}) async {
    try {
      final stockInRows = await _client
          .from('stock_entries')
          .select('*, products(name)')
          .gte('created_at', _startIso(start))
          .lte('created_at', _endIso(end));
      final salesRows = await _fetchSales(start, end, withProductName: true);
      final adjustmentRows = await _client
          .from('stock_adjustments')
          .select('*, products(name)')
          .gte('created_at', _startIso(start))
          .lte('created_at', _endIso(end));

      return aggregateStockMovement(
        stockInRows: (stockInRows as List).cast<Map<String, dynamic>>(),
        salesRows: salesRows,
        adjustmentRows: (adjustmentRows as List).cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      throw ReportsException('Could not load the stock movement report. Please check your connection.');
    }
  }
}
