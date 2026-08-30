import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sync_conflict.dart';
import '../services/supabase_service.dart';

class SyncConflictException implements Exception {
  SyncConflictException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class SyncConflictRepository {
  Future<List<SyncConflict>> listConflicts({bool includeResolved = false});
  Future<void> resolveConflict(String conflictId);
}

class SupabaseSyncConflictRepository implements SyncConflictRepository {
  SupabaseSyncConflictRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  @override
  Future<List<SyncConflict>> listConflicts(
      {bool includeResolved = false}) async {
    try {
      final result = await _client.rpc('list_sync_conflicts', params: {
        'p_include_resolved': includeResolved,
      });
      return (result as List)
          .map((row) =>
              SyncConflict.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw SyncConflictException(
          e.message.isNotEmpty ? e.message : 'Could not load sync conflicts.');
    }
  }

  @override
  Future<void> resolveConflict(String conflictId) async {
    try {
      await _client.rpc('resolve_sync_conflict', params: {
        'p_conflict_id': conflictId,
      });
    } on PostgrestException catch (e) {
      throw SyncConflictException(
          e.message.isNotEmpty ? e.message : 'Could not resolve conflict.');
    }
  }
}
