import '../../../core/localization/app_strings.dart';
import '../../../models/dashboard_stats.dart';

/// Identifies a dashboard KPI card for layout/icon mapping in the UI.
enum DashboardKpiKind {
  totalSales,
  saleCount,
  stockInCount,
  adjustmentCount,
  lowStockCount,
  activeProductCount,
}

/// One KPI row shown on the home dashboard.
class DashboardKpiDescriptor {
  const DashboardKpiDescriptor({
    required this.kind,
    required this.label,
    required this.value,
  });

  final DashboardKpiKind kind;
  final String label;
  final String value;
}

/// Builds role-scoped KPI descriptors for the home dashboard.
///
/// Owner/Manager (`shop` scope) see shop-wide totals including adjustment,
/// low-stock, and active-product counts. Staff (`self` scope) see only
/// their own sales and stock-in activity — no shop-wide sensitive data.
List<DashboardKpiDescriptor> buildDashboardKpis({
  required DashboardStats stats,
  int? activeProductCount,
  bool activeProductCountPending = false,
  bool activeProductCountError = false,
}) {
  const currency = AppStrings.currencySymbol;
  final base = <DashboardKpiDescriptor>[
    DashboardKpiDescriptor(
      kind: DashboardKpiKind.totalSales,
      label: AppStrings.totalSales,
      value: '$currency${stats.totalSalesAmount}',
    ),
    DashboardKpiDescriptor(
      kind: DashboardKpiKind.saleCount,
      label: AppStrings.salesCount,
      value: '${stats.saleCount}',
    ),
    DashboardKpiDescriptor(
      kind: DashboardKpiKind.stockInCount,
      label: AppStrings.stockInCount,
      value: '${stats.stockInCount}',
    ),
  ];

  if (!stats.isShopScope) {
    return base;
  }

  return [
    ...base,
    DashboardKpiDescriptor(
      kind: DashboardKpiKind.adjustmentCount,
      label: AppStrings.adjustmentCount,
      value: '${stats.adjustmentCount}',
    ),
    DashboardKpiDescriptor(
      kind: DashboardKpiKind.lowStockCount,
      label: AppStrings.lowStockProducts,
      value: '${stats.lowStockCount}',
    ),
    DashboardKpiDescriptor(
      kind: DashboardKpiKind.activeProductCount,
      label: AppStrings.activeProductCount,
      value: activeProductCountPending
          ? '...'
          : activeProductCountError
              ? '—'
              : '${activeProductCount ?? 0}',
    ),
  ];
}
