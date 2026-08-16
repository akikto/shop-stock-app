import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import '../services/supabase_service.dart';

class NotificationException implements Exception {
  NotificationException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class NotificationRepository {
  Future<List<AppNotification>> fetchNotifications({int limit = 50});
  Future<int> fetchUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  RealtimeChannel subscribeToNotifications(void Function() onChange);
}

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  @override
  Future<List<AppNotification>> fetchNotifications({int limit = 50}) async {
    try {
      final result = await _client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (result as List)
          .map((row) => AppNotification.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw NotificationException(e.message.isNotEmpty ? e.message : 'Could not load notifications.');
    } catch (_) {
      throw NotificationException('Could not load notifications.');
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
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _client.from('notifications').update({'read': true}).eq('id', id);
    } on PostgrestException catch (e) {
      throw NotificationException(e.message.isNotEmpty ? e.message : 'Could not update notification.');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client.from('notifications').update({'read': true}).eq('recipient_id', userId).eq('read', false);
    } on PostgrestException catch (e) {
      throw NotificationException(e.message.isNotEmpty ? e.message : 'Could not update notifications.');
    }
  }

  @override
  RealtimeChannel subscribeToNotifications(void Function() onChange) {
    final userId = _client.auth.currentUser?.id;
    return _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'recipient_id', value: userId ?? ''),
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
