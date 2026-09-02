import 'package:supabase_flutter/supabase_flutter.dart';

import 'in_memory_local_storage.dart';

/// VM/Android stub — [SupabaseService] only constructs this on web (`kIsWeb`).
class WebBrowserLocalStorage extends LocalStorage {
  WebBrowserLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;

  late final LocalStorage _delegate = InMemoryLocalStorage(
    persistSessionKey: persistSessionKey,
  );

  @override
  Future<void> initialize() => _delegate.initialize();

  @override
  Future<bool> hasAccessToken() => _delegate.hasAccessToken();

  @override
  Future<String?> accessToken() => _delegate.accessToken();

  @override
  Future<void> removePersistedSession() => _delegate.removePersistedSession();

  @override
  Future<void> persistSession(String persistSessionString) =>
      _delegate.persistSession(persistSessionString);
}
