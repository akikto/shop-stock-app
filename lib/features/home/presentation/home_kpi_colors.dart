import 'package:flutter/material.dart';

import '../domain/dashboard_kpi.dart';

/// Distinct background/accent colors for home dashboard KPI cards.
class HomeKpiColors {
  const HomeKpiColors._();

  static (Color background, Color accent, Color onAccent) style(
    DashboardKpiKind kind,
  ) =>
      switch (kind) {
        DashboardKpiKind.totalSales => (
            const Color(0xFFE8F5E9),
            const Color(0xFF2E7D32),
            const Color(0xFF1B5E20),
          ),
        DashboardKpiKind.saleCount => (
            const Color(0xFFE3F2FD),
            const Color(0xFF1565C0),
            const Color(0xFF0D47A1),
          ),
        DashboardKpiKind.stockInCount => (
            const Color(0xFFFFF3E0),
            const Color(0xFFEF6C00),
            const Color(0xFFE65100),
          ),
        DashboardKpiKind.adjustmentCount => (
            const Color(0xFFEDE7F6),
            const Color(0xFF5E35B1),
            const Color(0xFF4527A0),
          ),
        DashboardKpiKind.lowStockCount => (
            const Color(0xFFFFEBEE),
            const Color(0xFFC62828),
            const Color(0xFFB71C1C),
          ),
        DashboardKpiKind.activeProductCount => (
            const Color(0xFFE0F2F1),
            const Color(0xFF00695C),
            const Color(0xFF004D40),
          ),
      };

  static (Color background, Color accent) quickActionStyle(int index) {
    const styles = [
      (Color(0xFFFFF8E1), Color(0xFFF9A825)),
      (Color(0xFFE8EAF6), Color(0xFF3949AB)),
      (Color(0xFFF3E5F5), Color(0xFF8E24AA)),
      (Color(0xFFE0F7FA), Color(0xFF00838F)),
    ];
    return styles[index % styles.length];
  }
}
