import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity_log.dart';
import '../services/supabase_service.dart';

class ActivityLogException implements Exception {
  ActivityLogException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class ActivityLogRepository {
  /// Fetches a page of activity log entries, newest first, with actor
  /// names resolved (via `list_profiles_public()` — never exposing
  /// phone numbers, per the Phase 0 design). RLS itself already
  /// scopes what a given caller sees: Owner/Manager see everything,
  /// plain staff see only their own actions (see migration 0003's
  /// `activity_logs_select_manager_owner` policy).
  Future<List<ActivityLog>> fetchActivityLogs({int limit = 20, int offset = 0});
}

class SupabaseActivityLogRepository implements ActivityLogRepository {
  SupabaseActivityLogRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  @override
  Future<List<ActivityLog>> fetchActivityLogs(
      {int limit = 20, int offset = 0}) async {
    try {
      final rows = await _client
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final logs = (rows as List)
          .map((row) => ActivityLog.fromJson(row as Map<String, dynamic>))
          .toList();

      if (logs.isEmpty) return logs;

      final Map<String, String> nameById = {};
      try {
        final profiles = await _client.rpc('list_profiles_public') as List;
        for (final p in profiles) {
          final map = p as Map<String, dynamic>;
          nameById[map['id'] as String] = map['name'] as String;
        }
      } catch (_) {
        // Name resolution is a display nicety — if it fails, still
        // show the log entries (with actorName left null) rather than
        // failing the whole screen.
      }

      return logs
          .map((log) => log.copyWithActorName(nameById[log.actorId]))
          .toList();
    } on PostgrestException catch (e) {
      throw ActivityLogException(
          e.message.isNotEmpty ? e.message : 'Could not load history.');
    } catch (e) {
      throw ActivityLogException(
          'Could not load history. Please check your connection.');
    }
  }
}
