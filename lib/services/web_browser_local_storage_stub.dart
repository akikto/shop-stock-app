import 'package:supabase_flutter/supabase_flutter.dart';

/// Non-web stub — never instantiated; [SupabaseService] only uses the web
/// implementation when [kIsWeb] is true at runtime.
class WebBrowserLocalStorage extends LocalStorage {
  WebBrowserLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<void> removePersistedSession() async {}

  @override
  Future<void> persistSession(String persistSessionString) async {}
}
