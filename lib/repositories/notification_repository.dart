import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/localization/app_strings.dart';
import '../models/app_notification.dart';
import '../services/supabase_service.dart';

class NotificationException implements Exception {
  NotificationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Maps PostgREST failures to Bengali user-facing messages.
String resolveNotificationErrorMessage({
  required String serverMessage,
  required String fallbackMessage,
}) {
  return serverMessage.isNotEmpty ? serverMessage : fallbackMessage;
}

abstract class NotificationRepository {
  Future<List<AppNotification>> fetchNotifications({
    int limit = 50,
    int offset = 0,
  });
  Future<int> fetchUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<List<AppNotification>> fetchNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await _client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (result as List)
          .map((row) =>
              AppNotification.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw NotificationException(
        resolveNotificationErrorMessage(
          serverMessage: e.message,
          fallbackMessage: AppStrings.notificationsLoadFailed,
        ),
      );
    } catch (_) {
      throw NotificationException(AppStrings.notificationsLoadFailed);
    }
  }

  @override
  Future<int> fetchUnreadCount() async {
    try {
      final result = await _client
          .from('notifications')
          .select('id')
          .eq('read', false);
      return (result as List).length;
    } on PostgrestException catch (e) {
      throw NotificationException(
        resolveNotificationErrorMessage(
          serverMessage: e.message,
          fallbackMessage: AppStrings.unreadCountLoadFailed,
        ),
      );
    } catch (_) {
      throw NotificationException(AppStrings.unreadCountLoadFailed);
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    final userId = _userId;
    if (userId == null) {
      throw NotificationException(AppStrings.notificationUpdateFailed);
    }
    try {
      await _client.rpc('mark_notification_read', params: {
        'p_notification_id': id,
      });
    } on PostgrestException catch (e) {
      throw NotificationException(
        resolveNotificationErrorMessage(
          serverMessage: e.message,
          fallbackMessage: AppStrings.notificationUpdateFailed,
        ),
      );
    } catch (_) {
      throw NotificationException(AppStrings.notificationUpdateFailed);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _client.rpc('mark_all_notifications_read');
    } on PostgrestException catch (e) {
      throw NotificationException(
        resolveNotificationErrorMessage(
          serverMessage: e.message,
          fallbackMessage: AppStrings.notificationsUpdateFailed,
        ),
      );
    } catch (_) {
      throw NotificationException(AppStrings.notificationsUpdateFailed);
    }
  }
}
