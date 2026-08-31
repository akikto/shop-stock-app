import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/navigation/shell_navigation_provider.dart';
import '../../../core/utils/date_range.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/dashboard_stats.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/dashboard_kpi.dart';
import '../providers/dashboard_providers.dart';
import '../providers/notification_providers.dart';
import 'low_stock_screen.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';

/// Role-aware home dashboard with today's KPIs, low-stock summary,
/// and quick navigation to reports and notifications.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openReports(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationRealtimeProvider);
    ref.watch(productRealtimeProvider);

    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final canViewReports = profile?.role.canViewReports ?? false;
    final range = DateRange.today();
    final statsAsync = ref.watch(dashboardStatsProvider(range));
    final unreadAsync = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.home),
        actions: [
          if (canViewReports)
            IconButton(
              icon: const Icon(Icons.bar_chart_outlined),
              tooltip: AppStrings.reports,
              onPressed: () => _openReports(context),
            ),
          unreadAsync.when(
            data: (count) => IconButton(
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.notifications_outlined),
              ),
              tooltip: AppStrings.notifications,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen()),
              ),
            ),
            loading: () => IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider(range));
          ref.invalidate(unreadNotificationCountProvider);
          if (canViewReports) {
            ref.invalidate(activeProductCountProvider);
          }
        },
        child: statsAsync.when(
          loading: () =>
              const LoadingIndicator(message: AppStrings.loadingDashboard),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(dashboardStatsProvider(range)),
          ),
          data: (stats) {
            if (stats.isShopScope) {
              return _ShopScopedDashboard(
                stats: stats,
                canViewReports: canViewReports,
                onOpenReports: () => _openReports(context),
                onNavigateTab: (tab) =>
                    ref.read(shellNavigationIndexProvider.notifier).state = tab,
              );
            }

            return _DashboardBody(
              stats: stats,
              canViewReports: canViewReports,
              onOpenReports: () => _openReports(context),
              onNavigateTab: (tab) =>
                  ref.read(shellNavigationIndexProvider.notifier).state = tab,
            );
          },
        ),
      ),
    );
  }
}

/// Loads active-product count only for shop-scoped dashboards so staff
/// never trigger the extra products query.
class _ShopScopedDashboard extends ConsumerWidget {
  const _ShopScopedDashboard({
    required this.stats,
    required this.canViewReports,
    required this.onOpenReports,
    required this.onNavigateTab,
  });

  final DashboardStats stats;
  final bool canViewReports;
  final VoidCallback onOpenReports;
  final void Function(int tab) onNavigateTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCountAsync = ref.watch(activeProductCountProvider);

    return activeCountAsync.when(
      loading: () => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          LoadingIndicator(message: AppStrings.loadingDashboard),
        ],
      ),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(activeProductCountProvider),
      ),
      data: (activeCount) => _DashboardBody(
        stats: stats,
        activeProductCount: activeCount,
        canViewReports: canViewReports,
        onOpenReports: onOpenReports,
        onOpenLowStock: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const LowStockScreen()),
        ),
        onNavigateTab: onNavigateTab,
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.stats,
    required this.canViewReports,
    required this.onOpenReports,
    required this.onNavigateTab,
    this.activeProductCount,
    this.onOpenLowStock,
  });

  final DashboardStats stats;
  final int? activeProductCount;
  final bool canViewReports;
  final VoidCallback onOpenReports;
  final VoidCallback? onOpenLowStock;
  final void Function(int tab) onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final kpis = buildDashboardKpis(
      stats: stats,
      activeProductCount: activeProductCount,
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          stats.isShopScope ? AppStrings.todaySales : AppStrings.mySalesToday,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _KpiGrid(kpis: kpis),
        if (stats.isShopScope && stats.lowStockCount > 0 && onOpenLowStock != null) ...[
          const SizedBox(height: 20),
          _LowStockBanner(count: stats.lowStockCount, onTap: onOpenLowStock),
        ],
        const SizedBox(height: 24),
        Text(AppStrings.quickActions,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _QuickActions(
          canViewReports: canViewReports,
          onNewSale: () => onNavigateTab(ShellTab.sale),
          onStockIn: () => onNavigateTab(ShellTab.stockIn),
          onHistory: () => onNavigateTab(ShellTab.history),
          onReports: onOpenReports,
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final List<DashboardKpiDescriptor> kpis;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        for (final kpi in kpis) _KpiCard(descriptor: kpi),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.descriptor});

  final DashboardKpiDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (descriptor.kind) {
      DashboardKpiKind.totalSales => (Icons.payments_outlined, Colors.green),
      DashboardKpiKind.saleCount => (Icons.point_of_sale_outlined, Colors.blue),
      DashboardKpiKind.stockInCount => (Icons.add_box_outlined, Colors.orange),
      DashboardKpiKind.adjustmentCount =>
        (Icons.tune_outlined, Colors.deepPurple),
      DashboardKpiKind.lowStockCount =>
        (Icons.warning_amber_outlined, Colors.red),
      DashboardKpiKind.activeProductCount =>
        (Icons.inventory_2_outlined, Colors.teal),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Text(
              descriptor.value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(descriptor.label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.canViewReports,
    required this.onNewSale,
    required this.onStockIn,
    required this.onHistory,
    required this.onReports,
  });

  final bool canViewReports;
  final VoidCallback onNewSale;
  final VoidCallback onStockIn;
  final VoidCallback onHistory;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      _QuickActionTile(
        icon: Icons.point_of_sale_outlined,
        label: AppStrings.quickActionNewSale,
        onTap: onNewSale,
      ),
      _QuickActionTile(
        icon: Icons.add_box_outlined,
        label: AppStrings.quickActionStockIn,
        onTap: onStockIn,
      ),
      _QuickActionTile(
        icon: Icons.history_outlined,
        label: AppStrings.quickActionHistory,
        onTap: onHistory,
      ),
      if (canViewReports)
        _QuickActionTile(
          icon: Icons.bar_chart_outlined,
          label: AppStrings.reports,
          onTap: onReports,
        ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions,
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 48) / 2,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(child: Text(label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LowStockBanner extends StatelessWidget {
  const _LowStockBanner({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: Icon(Icons.warning_amber, color: Colors.red.shade700),
        title: Text('$count ${AppStrings.lowStockProducts}'),
        subtitle: const Text(AppStrings.viewLowStockList),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
