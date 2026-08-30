import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../models/user_role.dart';
import '../services/supabase_service.dart';

class StaffException implements Exception {
  StaffException(this.message);
  final String message;
  @override
  String toString() => message;
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.notifySale,
    required this.notifyStockIn,
    required this.notifyStockAdjustment,
    required this.notifyLowStock,
  });

  final bool notifySale;
  final bool notifyStockIn;
  final bool notifyStockAdjustment;
  final bool notifyLowStock;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      notifySale: json['notify_sale'] as bool? ?? true,
      notifyStockIn: json['notify_stock_in'] as bool? ?? true,
      notifyStockAdjustment: json['notify_stock_adjustment'] as bool? ?? true,
      notifyLowStock: json['notify_low_stock'] as bool? ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? notifySale,
    bool? notifyStockIn,
    bool? notifyStockAdjustment,
    bool? notifyLowStock,
  }) {
    return NotificationPreferences(
      notifySale: notifySale ?? this.notifySale,
      notifyStockIn: notifyStockIn ?? this.notifyStockIn,
      notifyStockAdjustment:
          notifyStockAdjustment ?? this.notifyStockAdjustment,
      notifyLowStock: notifyLowStock ?? this.notifyLowStock,
    );
  }
}

abstract class StaffRepository {
  Future<List<Profile>> listStaff();
  Future<void> updateRole(String userId, UserRole role);
  Future<void> setActive(String userId, bool isActive);
  Future<NotificationPreferences> getNotificationPreferences();
  Future<void> saveNotificationPreferences(NotificationPreferences prefs);
  Future<void> inviteStaff({
    required String email,
    required String name,
    required String password,
  });
}

class SupabaseStaffRepository implements StaffRepository {
  SupabaseStaffRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  @override
  Future<List<Profile>> listStaff() async {
    try {
      final result = await _client.rpc('list_staff_profiles');
      return (result as List)
          .map((row) => Profile.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw StaffException(e.message.isNotEmpty ? e.message : 'Could not load staff.');
    }
  }

  @override
  Future<void> updateRole(String userId, UserRole role) async {
    try {
      await _client.rpc('update_staff_role', params: {
        'p_user_id': userId,
        'p_role': role.name,
      });
    } on PostgrestException catch (e) {
      throw StaffException(e.message.isNotEmpty ? e.message : 'Could not update role.');
    }
  }

  @override
  Future<void> setActive(String userId, bool isActive) async {
    try {
      await _client.rpc('set_staff_active', params: {
        'p_user_id': userId,
        'p_is_active': isActive,
      });
    } on PostgrestException catch (e) {
      throw StaffException(e.message.isNotEmpty ? e.message : 'Could not update account.');
    }
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    try {
      final result = await _client.rpc('get_notification_preferences');
      return NotificationPreferences.fromJson(Map<String, dynamic>.from(result as Map));
    } on PostgrestException catch (e) {
      throw StaffException(e.message.isNotEmpty ? e.message : 'Could not load preferences.');
    }
  }

  @override
  Future<void> saveNotificationPreferences(NotificationPreferences prefs) async {
    try {
      await _client.rpc('upsert_notification_preferences', params: {
        'p_notify_sale': prefs.notifySale,
        'p_notify_stock_in': prefs.notifyStockIn,
        'p_notify_stock_adjustment': prefs.notifyStockAdjustment,
        'p_notify_low_stock': prefs.notifyLowStock,
      });
    } on PostgrestException catch (e) {
      throw StaffException(e.message.isNotEmpty ? e.message : 'Could not save preferences.');
    }
  }

  @override
  Future<void> inviteStaff({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'invite-staff',
        body: {
          'email': email.trim(),
          'name': name.trim(),
          'password': password,
        },
      );
      if (response.status != 200) {
        final data = response.data;
        final message = data is Map
            ? (data['error'] as String? ?? 'Could not create staff account.')
            : 'Could not create staff account.';
        throw StaffException(message);
      }
    } on StaffException {
      rethrow;
    } catch (e) {
      final message = e.toString();
      if (message.contains('Function not found') ||
          message.contains('Failed to fetch')) {
        throw StaffException(
            'Could not create staff account. Deploy the invite-staff edge function first.');
      }
      throw StaffException(
          message.isNotEmpty ? message : 'Could not create staff account.');
    }
  }
}
