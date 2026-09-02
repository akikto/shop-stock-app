import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory PKCE storage for web preview builds.
///
/// Avoids [SharedPreferencesGotrueAsyncStorage], which can throw on Flutter
/// web when the shared_preferences plugin is unavailable at startup.
class InMemoryGotrueAsyncStorage extends GotrueAsyncStorage {
  InMemoryGotrueAsyncStorage();

  final Map<String, String> _items = {};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> removeItem({required String key}) async {
    _items.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _items[key] = value;
  }
}
