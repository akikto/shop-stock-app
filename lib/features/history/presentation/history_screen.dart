import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/history_providers.dart';
import 'widgets/activity_log_tile.dart';

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
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(historyListControllerProvider.notifier).loadMore();
    }
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          LoadingIndicator(message: AppStrings.loadingHistory),
        ],
      );
    }

    if (state.error != null && state.logs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: ErrorView(
              message: state.error!,
              onRetry: () =>
                  ref.read(historyListControllerProvider.notifier).refresh(),
            ),
          ),
        ],
      );
    }

    if (state.logs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text(AppStrings.noHistoryFound)),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.logs.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.logs.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ActivityLogTile(log: state.logs[index]);
      },
    );
  }
}
