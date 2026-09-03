import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/navigation/shell_navigation_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/stock/presentation/stock_screen.dart';
import '../../../models/dashboard_stats.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/dashboard_kpi.dart';
import '../providers/dashboard_providers.dart';
import '../providers/notification_providers.dart';
import 'low_stock_screen.dart';
import 'home_kpi_colors.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';

/// Role-aware home dashboard with today's KPIs, low-stock summary,
/// and quick navigation — fits on one screen without scrolling.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openReports(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _refresh(
    WidgetRef ref, {
    required bool canViewReports,
  }) async {
    final range = ref.read(dashboardHomeRangeProvider);
    ref.invalidate(dashboardStatsProvider(range));
    ref.invalidate(unreadNotificationCountProvider);
    if (canViewReports) {
      ref.invalidate(shopActiveProductCountProvider);
    }
  }

  Widget _notificationBell({
    required BuildContext context,
    required int? count,
    required bool showBadge,
  }) {
    return IconButton(
      icon: Badge(
        isLabelVisible: showBadge,
        label: Text('${count ?? 0}'),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: AppStrings.notifications,
      onPressed: () => _openNotifications(context),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationRealtimeProvider);
    ref.watch(productRealtimeProvider);

    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final canViewReports = profile?.role.canViewReports ?? false;
    final range = ref.watch(dashboardHomeRangeProvider);
    final statsAsync = ref.watch(dashboardStatsProvider(range));
    final activeCountAsync = ref.watch(shopActiveProductCountProvider);
    final unreadAsync = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.home),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.retry,
            onPressed: () => _refresh(ref, canViewReports: canViewReports),
          ),
          if (canViewReports)
            IconButton(
              icon: const Icon(Icons.bar_chart_outlined),
              tooltip: AppStrings.reports,
              onPressed: () => _openReports(context),
            ),
          unreadAsync.when(
            skipLoadingOnReload: true,
            data: (count) => _notificationBell(
              context: context,
              count: count,
              showBadge: count > 0,
            ),
            loading: () => _notificationBell(
              context: context,
              count: unreadAsync.valueOrNull,
              showBadge: (unreadAsync.valueOrNull ?? 0) > 0,
            ),
            error: (_, __) => IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: AppStrings.notifications,
              onPressed: () => _openNotifications(context),
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        skipLoadingOnReload: true,
        loading: () =>
            const LoadingIndicator(message: AppStrings.loadingDashboard),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(dashboardStatsProvider(range)),
        ),
        data: (stats) => _DashboardBody(
          stats: stats,
          canViewReports: canViewReports,
          activeProductCount:
              stats.isShopScope ? activeCountAsync.valueOrNull : null,
          activeProductCountPending:
              stats.isShopScope && activeCountAsync.isLoading,
          activeProductCountError:
              stats.isShopScope && activeCountAsync.hasError,
          onOpenReports: () => _openReports(context),
          onOpenLowStock: stats.isShopScope && stats.lowStockCount > 0
              ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LowStockScreen(),
                    ),
                  )
              : null,
          onNavigateTab: (tab) =>
              ref.read(shellNavigationIndexProvider.notifier).state = tab,
          onStockIn: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const StockScreen()),
          ),
        ),
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
    required this.onStockIn,
    this.activeProductCount,
    this.activeProductCountPending = false,
    this.activeProductCountError = false,
    this.onOpenLowStock,
  });

  final DashboardStats stats;
  final int? activeProductCount;
  final bool activeProductCountPending;
  final bool activeProductCountError;
  final bool canViewReports;
  final VoidCallback onOpenReports;
  final VoidCallback? onOpenLowStock;
  final void Function(int tab) onNavigateTab;
  final VoidCallback onStockIn;

  @override
  Widget build(BuildContext context) {
    final kpis = buildDashboardKpis(
      stats: stats,
      activeProductCount: activeProductCount,
      activeProductCountPending: activeProductCountPending,
      activeProductCountError: activeProductCountError,
    );
    final showLowStock = stats.isShopScope &&
        stats.lowStockCount > 0 &&
        onOpenLowStock != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stats.isShopScope ? AppStrings.todaySales : AppStrings.mySalesToday,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: showLowStock ? 64 : 68,
            child: _KpiGrid(kpis: kpis),
          ),
          if (showLowStock) ...[
            const SizedBox(height: 8),
            _LowStockBanner(count: stats.lowStockCount, onTap: onOpenLowStock),
          ],
          const SizedBox(height: 10),
          Text(
            AppStrings.quickActions,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 24,
            child: _QuickActions(
              canViewReports: canViewReports,
              onNewSale: () => onNavigateTab(ShellTab.sale),
              onStockIn: onStockIn,
              onHistory: () => onNavigateTab(ShellTab.history),
              onReports: onOpenReports,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final List<DashboardKpiDescriptor> kpis;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = (kpis.length + 1) ~/ 2;
        const spacing = 8.0;
        final cellHeight =
            (constraints.maxHeight - spacing * (rows - 1)) / rows;

        return GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          mainAxisExtent: cellHeight,
          children: [
            for (final kpi in kpis) _KpiCard(descriptor: kpi),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.descriptor});

  final DashboardKpiDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    final (background, accent, onAccent) =
        HomeKpiColors.style(descriptor.kind);
    final icon = switch (descriptor.kind) {
      DashboardKpiKind.totalSales => Icons.payments_outlined,
      DashboardKpiKind.saleCount => Icons.point_of_sale_outlined,
      DashboardKpiKind.stockInCount => Icons.add_box_outlined,
      DashboardKpiKind.adjustmentCount => Icons.tune_outlined,
      DashboardKpiKind.lowStockCount => Icons.warning_amber_outlined,
      DashboardKpiKind.activeProductCount => Icons.inventory_2_outlined,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Icon(icon, color: accent, size: 16),
              ),
              const Spacer(),
              Text(
                descriptor.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onAccent,
                      height: 1.0,
                    ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  descriptor.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: onAccent.withValues(alpha: 0.9),
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
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
    final actions = <({IconData icon, String label, VoidCallback onTap})>[
      (
        icon: Icons.point_of_sale_outlined,
        label: AppStrings.quickActionNewSale,
        onTap: onNewSale,
      ),
      (
        icon: Icons.add_box_outlined,
        label: AppStrings.quickActionStockIn,
        onTap: onStockIn,
      ),
      (
        icon: Icons.history_outlined,
        label: AppStrings.quickActionHistory,
        onTap: onHistory,
      ),
      if (canViewReports)
        (
          icon: Icons.bar_chart_outlined,
          label: AppStrings.reports,
          onTap: onReports,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = (actions.length + 1) ~/ 2;
        const spacing = 8.0;
        final cellHeight =
            (constraints.maxHeight - spacing * (rows - 1)) / rows;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: cellHeight,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            final (background, accent) =
                HomeKpiColors.quickActionStyle(index);
            return _QuickActionTile(
              icon: action.icon,
              label: action.label,
              onTap: action.onTap,
              background: background,
              accent: accent,
            );
          },
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.background,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: accent.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                ),
              ),
            ],
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
    return Material(
      color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Color(0xFFC62828), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$count ${AppStrings.lowStockProducts}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFB71C1C),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFC62828), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
