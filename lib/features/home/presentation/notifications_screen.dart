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
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsListProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: const Text(AppStrings.markAllRead),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(notificationsListProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text(AppStrings.noNotifications));
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = notifications[i];
              return ListTile(
                leading: Icon(_iconForType(n.type), color: _colorForType(n.type)),
                title: Text(n.message),
                subtitle: Text(_formatTime(n.createdAt)),
                tileColor: n.read ? null : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15),
                onTap: () async {
                  if (!n.read) {
                    await ref.read(notificationRepositoryProvider).markAsRead(n.id);
                    ref.invalidate(notificationsListProvider);
                    ref.invalidate(unreadNotificationCountProvider);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  static IconData _iconForType(String type) {
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

  static Color _colorForType(String type) {
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

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
