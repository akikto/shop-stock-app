import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/features/home/domain/dashboard_kpi.dart';
import 'package:shop_stock_app/models/dashboard_stats.dart';

void main() {
  const shopStats = DashboardStats(
    roleScope: 'shop',
    saleCount: 10,
    totalSalesAmount: 1500,
    stockInCount: 3,
    adjustmentCount: 2,
    lowStockCount: 4,
  );

  const selfStats = DashboardStats(
    roleScope: 'self',
    saleCount: 2,
    totalSalesAmount: 200,
    stockInCount: 1,
    adjustmentCount: 0,
    lowStockCount: 0,
  );

  group('buildDashboardKpis', () {
    test('shop scope includes all six KPI kinds', () {
      final kpis = buildDashboardKpis(stats: shopStats, activeProductCount: 25);

      expect(kpis, hasLength(6));
      expect(
        kpis.map((k) => k.kind).toList(),
        [
          DashboardKpiKind.totalSales,
          DashboardKpiKind.saleCount,
          DashboardKpiKind.stockInCount,
          DashboardKpiKind.adjustmentCount,
          DashboardKpiKind.lowStockCount,
          DashboardKpiKind.activeProductCount,
        ],
      );
      expect(kpis.last.value, '25');
    });

    test('self scope exposes only personal sales activity', () {
      final kpis = buildDashboardKpis(stats: selfStats);

      expect(kpis, hasLength(3));
      expect(
        kpis.map((k) => k.kind).toList(),
        [
          DashboardKpiKind.totalSales,
          DashboardKpiKind.saleCount,
          DashboardKpiKind.stockInCount,
        ],
      );
      expect(
        kpis.any((k) => k.kind == DashboardKpiKind.lowStockCount),
        isFalse,
      );
      expect(
        kpis.any((k) => k.kind == DashboardKpiKind.activeProductCount),
        isFalse,
      );
    });

    test('formats currency and counts from stats', () {
      final kpis = buildDashboardKpis(stats: shopStats, activeProductCount: 5);
      final sales = kpis.firstWhere((k) => k.kind == DashboardKpiKind.totalSales);
      final adjustments =
          kpis.firstWhere((k) => k.kind == DashboardKpiKind.adjustmentCount);

      expect(sales.value, contains('1500'));
      expect(adjustments.value, '2');
    });

    test('shows placeholder while active product count is loading', () {
      final kpis = buildDashboardKpis(
        stats: shopStats,
        activeProductCountPending: true,
      );
      final active = kpis
          .firstWhere((k) => k.kind == DashboardKpiKind.activeProductCount);
      expect(active.value, '...');
    });

    test('shows dash when active product count failed', () {
      final kpis = buildDashboardKpis(
        stats: shopStats,
        activeProductCountError: true,
      );
      final active = kpis
          .firstWhere((k) => k.kind == DashboardKpiKind.activeProductCount);
      expect(active.value, '-');
    });
  });
}
