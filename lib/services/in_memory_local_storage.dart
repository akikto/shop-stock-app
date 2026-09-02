import 'package:supabase_flutter/supabase_flutter.dart';

/// Session storage that never touches platform plugins.
///
/// Used as the safe fallback for Flutter web preview startup when browser
/// [window.localStorage] is unavailable (private mode, blocked storage, etc.).
class InMemoryLocalStorage extends LocalStorage {
  InMemoryLocalStorage();

  String? _session;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => _session != null;

  @override
  Future<String?> accessToken() async => _session;

  @override
  Future<void> removePersistedSession() async {
    _session = null;
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    _session = persistSessionString;
  }
}
