import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationRealtimeProvider);
    final listState = ref.watch(notificationListControllerProvider);
    final controller = ref.read(notificationListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        actions: [
          TextButton(
            onPressed: listState.notifications.isEmpty
                ? null
                : () async {
                    await ref
                        .read(notificationRepositoryProvider)
                        .markAllAsRead();
                    controller.markAllLocalAsRead();
                    ref.invalidate(unreadNotificationCountProvider);
                  },
            child: const Text(AppStrings.markAllRead),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.refresh();
          ref.invalidate(unreadNotificationCountProvider);
        },
        child: _NotificationsBody(
          state: listState,
          onRetry: () => controller.refresh(),
          onLoadMore: controller.loadMore,
          onMarkRead: (id) async {
            await ref.read(notificationRepositoryProvider).markAsRead(id);
            controller.markLocalAsRead(id);
            ref.invalidate(unreadNotificationCountProvider);
          },
        ),
      ),
    );
  }

  static IconData iconForType(String type) {
    switch (type) {
      case 'sale':
        return Icons.point_of_sale;
      case 'stock_in':
        return Icons.add_box;
      case 'stock_adjustment':
        return Icons.tune;
      case 'low_stock':
        return Icons.warning_amber;
      default:
        return Icons.notifications;
    }
  }

  static Color colorForType(String type) {
    switch (type) {
      case 'sale':
        return Colors.green;
      case 'stock_in':
        return Colors.blue;
      case 'stock_adjustment':
        return Colors.orange;
      case 'low_stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody({
    required this.state,
    required this.onRetry,
    required this.onLoadMore,
    required this.onMarkRead,
  });

  final NotificationListState state;
  final VoidCallback onRetry;
  final Future<void> Function() onLoadMore;
  final Future<void> Function(String id) onMarkRead;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 240,
            child: LoadingIndicator(message: AppStrings.loadingNotifications),
          ),
        ],
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: ErrorView(message: state.error!, onRetry: onRetry),
          ),
        ],
      );
    }

    if (state.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 240,
            child: Center(child: Text(AppStrings.noNotifications)),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.notifications.length + 1,
      separatorBuilder: (_, index) {
        if (index >= state.notifications.length - 1) {
          return const SizedBox.shrink();
        }
        return const Divider(height: 1);
      },
      itemBuilder: (context, index) {
        if (index == state.notifications.length) {
          return _LoadMoreFooter(
            isLoadingMore: state.isLoadingMore,
            hasMore: state.hasMore,
            error: state.error,
            onLoadMore: onLoadMore,
            onRetry: onRetry,
          );
        }

        final n = state.notifications[index];
        return ListTile(
          leading: Icon(
            NotificationsScreen.iconForType(n.type),
            color: NotificationsScreen.colorForType(n.type),
          ),
          title: Text(n.message),
          subtitle: Text(NotificationsScreen.formatTime(n.createdAt)),
          tileColor: n.read
              ? null
              : Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.15),
          onTap: () async {
            if (!n.read) {
              await onMarkRead(n.id);
            }
          },
        );
      },
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRetry,
    this.error,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final Future<void> Function() onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ),
      );
    }

    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text(AppStrings.noMoreNotifications)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: OutlinedButton(
          onPressed: () => onLoadMore(),
          child: const Text(AppStrings.loadMoreNotifications),
        ),
      ),
    );
  }
}
