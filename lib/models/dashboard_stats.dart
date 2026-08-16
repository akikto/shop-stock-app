/// Dashboard KPIs returned by `get_dashboard_stats()` RPC.
class DashboardStats {
  const DashboardStats({
    required this.roleScope,
    required this.saleCount,
    required this.totalSalesAmount,
    required this.stockInCount,
    required this.adjustmentCount,
    required this.lowStockCount,
  });

  /// `shop` for manager/owner, `self` for staff.
  final String roleScope;
  final int saleCount;
  final num totalSalesAmount;
  final int stockInCount;
  final int adjustmentCount;
  final int lowStockCount;

  bool get isShopScope => roleScope == 'shop';

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      roleScope: json['role_scope'] as String? ?? 'self',
      saleCount: (json['sale_count'] as num?)?.toInt() ?? 0,
      totalSalesAmount: json['total_sales_amount'] as num? ?? 0,
      stockInCount: (json['stock_in_count'] as num?)?.toInt() ?? 0,
      adjustmentCount: (json['adjustment_count'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['low_stock_count'] as num?)?.toInt() ?? 0,
    );
  }
}
