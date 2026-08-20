import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/activity_log.dart';
import '../providers/history_providers.dart';

/// Permanent activity history — reads activity_logs (immutable,
/// insert-only via the RPC functions). RLS already scopes what a
/// given caller sees (Owner/Manager: everything; staff: only their
/// own actions), so this screen itself needs no extra role logic.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(historyListControllerProvider.notifier).loadMore();
    }
  }

  static String _actionLabel(String action) {
    switch (action) {
      case 'sale':
        return AppStrings.actionSale;
      case 'stock_in':
        return AppStrings.actionStockIn;
      case 'stock_adjustment':
        return AppStrings.actionStockAdjustment;
      case 'product_created':
        return AppStrings.actionProductCreated;
      case 'product_updated':
        return AppStrings.actionProductUpdated;
      case 'price_updated':
        return AppStrings.actionPriceUpdated;
      case 'product_deactivated':
        return AppStrings.actionProductDeactivated;
      case 'product_activated':
        return AppStrings.actionProductActivated;
      default:
        return action;
    }
  }

  static IconData _actionIcon(String action) {
    switch (action) {
      case 'sale':
        return Icons.point_of_sale;
      case 'stock_in':
        return Icons.add_box;
      case 'stock_adjustment':
        return Icons.tune;
      case 'product_created':
        return Icons.fiber_new;
      case 'product_updated':
      case 'price_updated':
        return Icons.edit;
      case 'product_deactivated':
        return Icons.block;
      case 'product_activated':
        return Icons.check_circle_outline;
      default:
        return Icons.history;
    }
  }

  String _subtitle(ActivityLog log) {
    final parts = <String>[];
    if (log.productName != null) parts.add(log.productName!);
    if (log.actorName != null) parts.add(log.actorName!);
    final local = log.createdAt.toLocal();
    final date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    parts.add(date);
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.history)),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(historyListControllerProvider.notifier).refresh(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(HistoryListState state) {
    if (state.isLoading && state.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.logs.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(state.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref
                        .read(historyListControllerProvider.notifier)
                        .refresh(),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (state.logs.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text(AppStrings.noHistoryFound)),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.logs.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= state.logs.length) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()));
        }
        final log = state.logs[index];
        return ListTile(
          leading: CircleAvatar(child: Icon(_actionIcon(log.action), size: 20)),
          title: Text(_actionLabel(log.action)),
          subtitle: Text(_subtitle(log)),
        );
      },
    );
  }
}
