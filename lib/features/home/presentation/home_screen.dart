import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/product.dart';
import '../../../services/report_calculations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/reports_providers.dart';

/// Home dashboard (Phase 4). Owner/Manager see the full Reports
/// section (daily/staff-wise/product-wise sales, stock movement) —
/// RLS already restricts what a staff caller could even fetch here
/// (see migration 0003), so this role gate is a UI convenience on top
/// of, not instead of, that server-side enforcement. Low-stock is
/// visible to every role, since `products` is readable by all
/// authenticated users regardless.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final canViewReports = profileAsync.maybeWhen(data: (p) => p.role.canViewReports, orElse: () => false);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dashboard)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailySalesProvider);
          ref.invalidate(staffWiseSalesProvider);
          ref.invalidate(productWiseSalesProvider);
          ref.invalidate(stockMovementProvider);
          ref.invalidate(lowStockProductsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _LowStockSection(),
            const SizedBox(height: 20),
            if (canViewReports) ...[
              const _RangeSelector(),
              const SizedBox(height: 12),
              const _DailySalesSection(),
              const SizedBox(height: 20),
              const _StaffWiseSection(),
              const SizedBox(height: 20),
              const _ProductWiseSection(),
              const SizedBox(height: 20),
              const _StockMovementSection(),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  AppStrings.reportsOwnerManagerOnly,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _RangeSelector extends ConsumerWidget {
  const _RangeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateRangeProvider);
    return SegmentedButton<ReportRangePreset>(
      segments: const [
        ButtonSegment(value: ReportRangePreset.today, label: Text(AppStrings.today)),
        ButtonSegment(value: ReportRangePreset.last7Days, label: Text(AppStrings.last7Days)),
        ButtonSegment(value: ReportRangePreset.last30Days, label: Text(AppStrings.last30Days)),
      ],
      selected: {range.preset},
      onSelectionChanged: (selection) {
        ref.read(reportDateRangeProvider.notifier).state = ReportDateRange.forPreset(selection.first);
      },
    );
  }
}

class _LowStockSection extends ConsumerWidget {
  const _LowStockSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(lowStockProductsProvider);
    return _SectionCard(
      title: AppStrings.lowStockAlerts,
      child: asyncProducts.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
        error: (e, _) => Text(e.toString()),
        data: (products) {
          if (products.isEmpty) return const Text(AppStrings.noLowStockProducts);
          return Column(
            children: [
              for (final Product p in products)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                  title: Text(p.name),
                  trailing: Text('${p.currentStock} / ${p.lowStockLimit}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DailySalesSection extends ConsumerWidget {
  const _DailySalesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPoints = ref.watch(dailySalesProvider);
    return _SectionCard(
      title: AppStrings.dailySales,
      child: asyncPoints.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
        error: (e, _) => Text(e.toString()),
        data: (points) {
          if (points.isEmpty) return const Text(AppStrings.noSalesInRange);
          final totalAmount = points.fold<num>(0, (sum, p) => sum + p.totalAmount);
          final totalCount = points.fold<int>(0, (sum, p) => sum + p.saleCount);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${AppStrings.totalSales}: ৳$totalAmount', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${AppStrings.totalTransactions}: $totalCount'),
                ],
              ),
              const Divider(),
              for (final point in points)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(_formatDate(point.date)),
                  trailing: Text('৳${point.totalAmount}  (${point.saleCount})'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StaffWiseSection extends ConsumerWidget {
  const _StaffWiseSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummaries = ref.watch(staffWiseSalesProvider);
    return _SectionCard(
      title: AppStrings.staffWiseSales,
      child: asyncSummaries.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
        error: (e, _) => Text(e.toString()),
        data: (summaries) {
          if (summaries.isEmpty) return const Text(AppStrings.noSalesInRange);
          return Column(
            children: [
              for (final s in summaries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(s.userName),
                  subtitle: Text('${s.saleCount} ${AppStrings.totalTransactions}'),
                  trailing: Text('৳${s.totalAmount}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductWiseSection extends ConsumerWidget {
  const _ProductWiseSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummaries = ref.watch(productWiseSalesProvider);
    return _SectionCard(
      title: AppStrings.productWiseSales,
      child: asyncSummaries.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
        error: (e, _) => Text(e.toString()),
        data: (summaries) {
          if (summaries.isEmpty) return const Text(AppStrings.noSalesInRange);
          return Column(
            children: [
              for (final s in summaries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(s.productName),
                  subtitle: Text('${AppStrings.quantity}: ${s.totalQuantity}'),
                  trailing: Text('৳${s.totalAmount}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StockMovementSection extends ConsumerWidget {
  const _StockMovementSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummaries = ref.watch(stockMovementProvider);
    return _SectionCard(
      title: AppStrings.stockMovement,
      child: asyncSummaries.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
        error: (e, _) => Text(e.toString()),
        data: (summaries) {
          if (summaries.isEmpty) return const Text(AppStrings.noMovementInRange);
          return Column(
            children: [
              for (final StockMovementSummary s in summaries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${AppStrings.stockIn}: +${s.stockIn}   ${AppStrings.sold}: -${s.sold}   '
                        '${AppStrings.adjusted}: ${s.adjustedNet >= 0 ? "+" : ""}${s.adjustedNet}   '
                        '${AppStrings.netChange}: ${s.netChange >= 0 ? "+" : ""}${s.netChange}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
