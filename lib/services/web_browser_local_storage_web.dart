import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart';

/// Persists Supabase auth sessions in `window.localStorage` on web.
///
/// Used instead of [SharedPreferencesLocalStorage], which falls back to
/// shared_preferences on many Flutter web builds and can crash at startup.
class WebBrowserLocalStorage extends LocalStorage {
  WebBrowserLocalStorage({required this.persistSessionKey});

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
