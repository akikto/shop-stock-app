import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/app_notification.dart';
import '../../../repositories/notification_repository.dart';
import '../../../services/supabase_service.dart';
import 'dashboard_refresh.dart';

const int notificationPageSize = 50;

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository();
});

final unreadNotificationCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.fetchUnreadCount();
});

class NotificationListState {
  const NotificationListState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  NotificationListState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationListController extends StateNotifier<NotificationListState> {
  NotificationListController(this._repo) : super(const NotificationListState()) {
    loadFirstPage();
  }

  final NotificationRepository _repo;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _repo.fetchNotifications(
        limit: notificationPageSize,
        offset: 0,
      );
      state = state.copyWith(
        notifications: page,
        isLoading: false,
        hasMore: page.length == notificationPageSize,
      );
    } on NotificationException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final more = await _repo.fetchNotifications(
        limit: notificationPageSize,
        offset: state.notifications.length,
      );
      state = state.copyWith(
        notifications: [...state.notifications, ...more],
        isLoadingMore: false,
        hasMore: more.length == notificationPageSize,
      );
    } on NotificationException catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.message);
    }
  }

  Future<void> refresh({bool preserveVisibleList = false}) async {
    if (preserveVisibleList && state.notifications.isNotEmpty) {
      try {
        final page = await _repo.fetchNotifications(
          limit: notificationPageSize,
          offset: 0,
        );
        state = state.copyWith(
          notifications: page,
          isLoading: false,
          hasMore: page.length == notificationPageSize,
          clearError: true,
        );
      } on NotificationException catch (e) {
        state = state.copyWith(error: e.message);
      }
      return;
    }
    await loadFirstPage();
  }

  void markLocalAsRead(String id) {
    state = state.copyWith(
      notifications: [
        for (final n in state.notifications)
          if (n.id == id)
            AppNotification(
              id: n.id,
              type: n.type,
              message: n.message,
              read: true,
              createdAt: n.createdAt,
            )
          else
            n,
      ],
    );
  }

  void markAllLocalAsRead() {
    state = state.copyWith(
      notifications: [
        for (final n in state.notifications)
          AppNotification(
            id: n.id,
            type: n.type,
            message: n.message,
            read: true,
            createdAt: n.createdAt,
          ),
      ],
    );
  }
}

final notificationListControllerProvider =
    StateNotifierProvider.autoDispose<NotificationListController,
        NotificationListState>((ref) {
  return NotificationListController(ref.watch(notificationRepositoryProvider));
});

/// Single authoritative Realtime subscription for in-app notifications.
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
          value: userId,
        ),
        callback: (_) {
          ref.invalidate(unreadNotificationCountProvider);
          final list = ref.read(notificationListControllerProvider.notifier);
          unawaited(list.refresh(preserveVisibleList: true));
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
  final refresh = ref.watch(debouncedDashboardRefreshProvider);

  final channel = client
      .channel('products-realtime')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'products',
        callback: (_) => refresh.schedule(),
      )
      .subscribe();

  ref.onDispose(() {
    unawaited(client.removeChannel(channel));
  });
});
