/// Pure aggregation functions for the Reports dashboard (Phase 4).
///
/// Deliberately separated from ReportsRepository's Supabase fetch
/// calls, mirroring the pattern already used for image resize math
/// (lib/services/image_resize_math.dart) — the actual calculation
/// logic is unit-testable without a live backend, while the
/// repository stays a thin fetch-and-hand-off layer.
///
/// A shop's transaction volume is small enough that client-side
/// aggregation over a fetched date range is appropriate — this avoids
/// adding new SQL views/functions for reports that the existing
/// tables and RLS policies already support reading.
library;

class DailySalesPoint {
  const DailySalesPoint({required this.date, required this.totalAmount, required this.saleCount});
  final DateTime date; // date-only, local
  final num totalAmount;
  final int saleCount;
}

class StaffSalesSummary {
  const StaffSalesSummary({
    required this.userId,
    required this.userName,
    required this.totalAmount,
    required this.saleCount,
  });
  final String userId;
  final String userName;
  final num totalAmount;
  final int saleCount;
}

class ProductSalesSummary {
  const ProductSalesSummary({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalAmount,
  });
  final String productId;
  final String productName;
  final num totalQuantity;
  final num totalAmount;
}

class StockMovementSummary {
  const StockMovementSummary({
    required this.productId,
    required this.productName,
    required this.stockIn,
    required this.sold,
    required this.adjustedNet,
  });
  final String productId;
  final String productName;
  final num stockIn;
  final num sold;
  final num adjustedNet; // sum of quantity_change, can be +/-

  num get netChange => stockIn - sold + adjustedNet;
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// [salesRows] — raw rows as returned by Supabase for `sales`, each
/// expected to have `created_at`, `total_amount`.
List<DailySalesPoint> aggregateDailySales(List<Map<String, dynamic>> salesRows) {
  final byDay = <DateTime, List<Map<String, dynamic>>>{};
  for (final row in salesRows) {
    final day = _dateOnly(DateTime.parse(row['created_at'] as String).toLocal());
    byDay.putIfAbsent(day, () => []).add(row);
  }
  final points = byDay.entries.map((e) {
    final total = e.value.fold<num>(0, (sum, r) => sum + (r['total_amount'] as num));
    return DailySalesPoint(date: e.key, totalAmount: total, saleCount: e.value.length);
  }).toList();
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

/// [salesRows] must have `user_id`, `total_amount`. [nameById] resolves
/// display names (from list_profiles_public()); a missing id falls
/// back to the raw id string rather than failing.
List<StaffSalesSummary> aggregateStaffSales(
  List<Map<String, dynamic>> salesRows,
  Map<String, String> nameById,
) {
  final byUser = <String, List<Map<String, dynamic>>>{};
  for (final row in salesRows) {
    byUser.putIfAbsent(row['user_id'] as String, () => []).add(row);
  }
  final summaries = byUser.entries.map((e) {
    final total = e.value.fold<num>(0, (sum, r) => sum + (r['total_amount'] as num));
    return StaffSalesSummary(
      userId: e.key,
      userName: nameById[e.key] ?? e.key,
      totalAmount: total,
      saleCount: e.value.length,
    );
  }).toList();
  summaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  return summaries;
}

/// [salesRows] must have `product_id`, `quantity`, `total_amount`, and
/// optionally an embedded `products` map with `name` (from a Supabase
/// `.select('*, products(name)')` query) — falls back to the raw id.
List<ProductSalesSummary> aggregateProductSales(List<Map<String, dynamic>> salesRows) {
  final byProduct = <String, List<Map<String, dynamic>>>{};
  for (final row in salesRows) {
    byProduct.putIfAbsent(row['product_id'] as String, () => []).add(row);
  }
  final summaries = byProduct.entries.map((e) {
    final quantity = e.value.fold<num>(0, (sum, r) => sum + (r['quantity'] as num));
    final total = e.value.fold<num>(0, (sum, r) => sum + (r['total_amount'] as num));
    final productMap = e.value.first['products'] as Map<String, dynamic>?;
    final name = productMap?['name'] as String? ?? e.key;
    return ProductSalesSummary(productId: e.key, productName: name, totalQuantity: quantity, totalAmount: total);
  }).toList();
  summaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  return summaries;
}

/// Combines stock_entries (+), sales (-), and stock_adjustments (+/-)
/// for the same date range into a single per-product movement table.
/// Each row list must carry `product_id` and an embedded `products`
/// map with `name`; stockInRows use `quantity`, salesRows use
/// `quantity`, adjustmentRows use `quantity_change`.
List<StockMovementSummary> aggregateStockMovement({
  required List<Map<String, dynamic>> stockInRows,
  required List<Map<String, dynamic>> salesRows,
  required List<Map<String, dynamic>> adjustmentRows,
}) {
  final productNames = <String, String>{};
  final stockInByProduct = <String, num>{};
  final soldByProduct = <String, num>{};
  final adjustedByProduct = <String, num>{};

  void trackName(Map<String, dynamic> row) {
    final id = row['product_id'] as String;
    final productMap = row['products'] as Map<String, dynamic>?;
    if (productMap != null && productMap['name'] != null) {
      productNames[id] = productMap['name'] as String;
    }
  }

  for (final row in stockInRows) {
    trackName(row);
    final id = row['product_id'] as String;
    stockInByProduct[id] = (stockInByProduct[id] ?? 0) + (row['quantity'] as num);
  }
  for (final row in salesRows) {
    trackName(row);
    final id = row['product_id'] as String;
    soldByProduct[id] = (soldByProduct[id] ?? 0) + (row['quantity'] as num);
  }
  for (final row in adjustmentRows) {
    trackName(row);
    final id = row['product_id'] as String;
    adjustedByProduct[id] = (adjustedByProduct[id] ?? 0) + (row['quantity_change'] as num);
  }

  final allProductIds = {...stockInByProduct.keys, ...soldByProduct.keys, ...adjustedByProduct.keys};

  final summaries = allProductIds.map((id) {
    return StockMovementSummary(
      productId: id,
      productName: productNames[id] ?? id,
      stockIn: stockInByProduct[id] ?? 0,
      sold: soldByProduct[id] ?? 0,
      adjustedNet: adjustedByProduct[id] ?? 0,
    );
  }).toList();

  summaries.sort((a, b) => a.productName.compareTo(b.productName));
  return summaries;
}
