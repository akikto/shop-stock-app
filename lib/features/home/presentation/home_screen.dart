import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/date_range.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/dashboard_stats.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/dashboard_providers.dart';
import '../providers/notification_providers.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';

/// Role-aware home dashboard with today's KPIs, low-stock summary,
/// and quick navigation to reports and notifications.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
              ),
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
                MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
              ),
            ),
            loading: () => IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
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
        },
        child: statsAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading dashboard...'),
          // Kept in English — transient state before Bengali context is ready.
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(dashboardStatsProvider(range)),
          ),
          data: (stats) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                stats.isShopScope ? AppStrings.todaySales : AppStrings.mySalesToday,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _KpiGrid(stats: stats),
              if (stats.isShopScope && stats.lowStockCount > 0) ...[
                const SizedBox(height: 20),
                _LowStockBanner(count: stats.lowStockCount),
              ],
              if (canViewReports) ...[
                const SizedBox(height: 24),
                Text(AppStrings.quickActions, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text(AppStrings.viewReports),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _KpiCard(
        label: AppStrings.totalSales,
        value: '${AppStrings.currencySymbol}${stats.totalSalesAmount}',
        icon: Icons.payments_outlined,
        color: Colors.green,
      ),
      _KpiCard(
        label: AppStrings.salesCount,
        value: '${stats.saleCount}',
        icon: Icons.point_of_sale_outlined,
        color: Colors.blue,
      ),
      _KpiCard(
        label: AppStrings.stockInCount,
        value: '${stats.stockInCount}',
        icon: Icons.add_box_outlined,
        color: Colors.orange,
      ),
    ];

    if (stats.isShopScope) {
      cards.add(
        _KpiCard(
          label: AppStrings.lowStockProducts,
          value: '${stats.lowStockCount}',
          icon: Icons.warning_amber_outlined,
          color: Colors.red,
        ),
      );
    } else {
      cards.add(
        _KpiCard(
          label: AppStrings.totalActivity,
          value: '${stats.saleCount + stats.stockInCount}',
          icon: Icons.receipt_long_outlined,
          color: Colors.teal,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards,
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LowStockBanner extends StatelessWidget {
  const _LowStockBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: Icon(Icons.warning_amber, color: Colors.red.shade700),
        title: Text('$count ${AppStrings.lowStockProducts}'),
        subtitle: const Text(AppStrings.checkProductsTab),
      ),
    );
  }
}
