import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/date_range.dart';
import '../../../models/product_sales_row.dart';
import '../../../models/staff_sales_row.dart';
import '../../../models/stock_movement_row.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/dashboard_providers.dart';

/// Manager/Owner sales reports with date range and tabbed views.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  DateRange _range = DateRange.today();
  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  void _setToday() => setState(() => _range = DateRange.today());
  void _setLast7Days() => setState(() => _range = DateRange.last7Days());

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialStart = _range.isCustom()
        ? _range.from
        : now.subtract(const Duration(days: 6));
    final initialEnd = _range.isCustom()
        ? _range.to.subtract(const Duration(days: 1))
        : now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: AppStrings.pickDateRange,
    );

    if (picked == null || !mounted) return;

    try {
      setState(() => _range = DateRange.custom(picked.start, picked.end));
    } on InvalidDateRangeException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.invalidDateRange)),
      );
    }
  }

  Future<void> _refreshStaff() async =>
      ref.invalidate(staffSalesReportProvider(_range));

  Future<void> _refreshProduct() async =>
      ref.invalidate(productSalesReportProvider(_range));

  Future<void> _refreshMovement() async =>
      ref.invalidate(stockMovementReportProvider(_range));

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffSalesReportProvider(_range));
    final productAsync = ref.watch(productSalesReportProvider(_range));
    final movementAsync = ref.watch(stockMovementReportProvider(_range));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppStrings.staffWiseSales),
            Tab(text: AppStrings.productWiseSales),
            Tab(text: AppStrings.stockMovementReport),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text(AppStrings.today),
                  selected: _range.isToday(),
                  onSelected: (_) => _setToday(),
                ),
                ChoiceChip(
                  label: const Text(AppStrings.last7Days),
                  selected: _range.isLast7Days(),
                  onSelected: (_) => _setLast7Days(),
                ),
                ChoiceChip(
                  label: Text(
                    _range.isCustom()
                        ? AppStrings.customDateRange
                        : AppStrings.pickDateRange,
                  ),
                  selected: _range.isCustom(),
                  onSelected: (_) => _pickCustomRange(),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                staffAsync.when(
                  loading: () => const LoadingIndicator(
                    message: AppStrings.loadingReports,
                  ),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: _refreshStaff,
                  ),
                  data: (rows) => _StaffReportList(
                    rows: rows,
                    onRefresh: _refreshStaff,
                  ),
                ),
                productAsync.when(
                  loading: () => const LoadingIndicator(
                    message: AppStrings.loadingReports,
                  ),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: _refreshProduct,
                  ),
                  data: (rows) => _ProductReportList(
                    rows: rows,
                    onRefresh: _refreshProduct,
                  ),
                ),
                movementAsync.when(
                  loading: () => const LoadingIndicator(
                    message: AppStrings.loadingReports,
                  ),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: _refreshMovement,
                  ),
                  data: (rows) => _StockMovementList(
                    rows: rows,
                    onRefresh: _refreshMovement,
                  ),
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
  const _StaffReportList({required this.rows, required this.onRefresh});

  final List<StaffSalesRow> rows;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: rows.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text(AppStrings.noReportData)),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final row = rows[i];
                return ListTile(
                  title: Text(row.userName),
                  subtitle: Text(AppStrings.reportSaleCount(row.saleCount)),
                  trailing: Text(
                    '${row.totalAmount}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              },
            ),
    );
  }
}

class _ProductReportList extends StatelessWidget {
  const _ProductReportList({required this.rows, required this.onRefresh});

  final List<ProductSalesRow> rows;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: rows.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text(AppStrings.noReportData)),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final row = rows[i];
                return ListTile(
                  title: Text(row.productName),
                  subtitle: Text(AppStrings.reportProductSubtitle(
                    row.saleCount,
                    row.totalQuantity,
                  )),
                  trailing: Text(
                    '${row.totalAmount}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              },
            ),
    );
  }
}

class _StockMovementList extends StatelessWidget {
  const _StockMovementList({required this.rows, required this.onRefresh});

  final List<StockMovementRow> rows;
  final Future<void> Function() onRefresh;

  String _movementLabel(String type) {
    switch (type) {
      case 'sale':
        return AppStrings.movementSale;
      case 'stock_in':
        return AppStrings.movementStockIn;
      case 'stock_adjustment':
        return AppStrings.movementAdjustment;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: rows.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text(AppStrings.noReportData)),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final row = rows[i];
                final changePrefix = row.quantityChange >= 0 ? '+' : '';
                return ListTile(
                  title: Text(row.productName),
                  subtitle: Text(
                    '${_movementLabel(row.movementType)} · ${row.userName}\n'
                    '${row.createdAt.toLocal()}',
                  ),
                  trailing: Text(
                    '$changePrefix${row.quantityChange}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              },
            ),
    );
  }
}
