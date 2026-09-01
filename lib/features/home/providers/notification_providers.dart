import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/app_notification.dart';
import '../../../repositories/notification_repository.dart';
import '../../../services/supabase_service.dart';
import 'dashboard_providers.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository();
});

final unreadNotificationCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.fetchUnreadCount();
});

final notificationsListProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.fetchNotifications();
});

/// Subscribes to Supabase Realtime for notifications and invalidates
/// the count/list providers when new rows arrive.
final notificationRealtimeProvider = Provider.autoDispose<void>((ref) {
  final client = SupabaseService.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return;

  final channel = client
      .channel('notifications-realtime:$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId),
        callback: (_) {
          ref.invalidate(unreadNotificationCountProvider);
          ref.invalidate(notificationsListProvider);
        },
      )
      .subscribe();

  ref.onDispose(() {
    unawaited(client.removeChannel(channel));
  });
});

/// Subscribes to product stock changes so the dashboard can refresh.
final productRealtimeProvider = Provider.autoDispose<void>((ref) {
  final client = SupabaseService.client;

  final channel = client
      .channel('products-realtime')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'products',
        callback: (_) {
          final range = ref.read(dashboardHomeRangeProvider);
          ref.invalidate(dashboardStatsProvider(range));
          ref.invalidate(activeProductCountProvider);
        },
      )
      .subscribe();

  ref.onDispose(() {
    unawaited(client.removeChannel(channel));
  });
});
