import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart';

import 'in_memory_local_storage.dart';

/// Web session storage: prefers [window.localStorage], falls back to memory.
///
/// Never uses shared_preferences, which is the source of the preview null-check
/// crash on GitHub Pages.
class WebBrowserLocalStorage extends LocalStorage {
  WebBrowserLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;

  LocalStorage? _fallback;

  LocalStorage get _active =>
      _fallback ?? _BrowserLocalStorage(persistSessionKey);

  @override
  Future<void> initialize() async {
    try {
      final storage = window.localStorage;
      final probeKey = '$persistSessionKey.__probe__';
      storage.setItem(probeKey, '1');
      storage.removeItem(probeKey);
    } catch (_) {
      _fallback = InMemoryLocalStorage();
    }
    await _active.initialize();
  }

  @override
  Future<bool> hasAccessToken() => _active.hasAccessToken();

  @override
  Future<String?> accessToken() => _active.accessToken();

  @override
  Future<void> removePersistedSession() => _active.removePersistedSession();

  @override
  Future<void> persistSession(String persistSessionString) =>
      _active.persistSession(persistSessionString);
}

class _BrowserLocalStorage extends LocalStorage {
  _BrowserLocalStorage(this.persistSessionKey);

  final String persistSessionKey;

  Storage get _storage => window.localStorage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      _storage.getItem(persistSessionKey) != null;

  @override
  Future<String?> accessToken() async => _storage.getItem(persistSessionKey);

  @override
  Future<void> removePersistedSession() async {
    _storage.removeItem(persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    _storage.setItem(persistSessionKey, persistSessionString);
  }
}
