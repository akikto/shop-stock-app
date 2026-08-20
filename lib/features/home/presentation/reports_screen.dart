import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/date_range.dart';
import '../../../models/product_sales_row.dart';
import '../../../models/staff_sales_row.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/dashboard_providers.dart';

/// Manager/Owner sales reports with date range and tabbed views.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late DateRange _range = DateRange.today();
  late final TabController _tabController = TabController(length: 2, vsync: this);

  void _setToday() => setState(() => _range = DateRange.today());
  void _setLast7Days() => setState(() => _range = DateRange.last7Days());

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffSalesReportProvider(_range));
    final productAsync = ref.watch(productSalesReportProvider(_range));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppStrings.staffWiseSales),
            Tab(text: AppStrings.productWiseSales),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text(AppStrings.today),
                  selected: _range.from.day == DateTime.now().day && _range.to.difference(_range.from).inDays == 1,
                  onSelected: (_) => _setToday(),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text(AppStrings.last7Days),
                  selected: _range.to.difference(_range.from).inDays == 7,
                  onSelected: (_) => _setLast7Days(),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                staffAsync.when(
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(staffSalesReportProvider(_range))),
                  data: (rows) => _StaffReportList(rows: rows),
                ),
                productAsync.when(
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(productSalesReportProvider(_range))),
                  data: (rows) => _ProductReportList(rows: rows),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffReportList extends StatelessWidget {
  const _StaffReportList({required this.rows});

  final List<StaffSalesRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text(AppStrings.noReportData));
    }
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final row = rows[i];
        return ListTile(
          title: Text(row.userName),
          subtitle: Text('${row.saleCount} sales'),
          trailing: Text(
            '${AppStrings.currencySymbol}${row.totalAmount}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );
      },
    );
  }
}

class _ProductReportList extends StatelessWidget {
  const _ProductReportList({required this.rows});

  final List<ProductSalesRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text(AppStrings.noReportData));
    }
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final row = rows[i];
        return ListTile(
          title: Text(row.productName),
          subtitle: Text('${row.saleCount} sales · qty ${row.totalQuantity}'),
          trailing: Text(
            '${AppStrings.currencySymbol}${row.totalAmount}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );
      },
    );
  }
}
