import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/config/startup_config.dart';
import 'in_memory_gotrue_storage.dart';
import 'web_browser_local_storage.dart';

/// Thin wrapper around the Supabase client lifecycle.
///
/// Only ever initialized with the public anon key (see [AppConfig]).
/// All authorization is enforced server-side by Postgres Row Level
/// Security — this class does not, and must not, contain any
/// privileged logic.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static String _sessionStorageKey(String url) =>
      'sb-${Uri.parse(url).host.split('.').first}-auth-token';

  static FlutterAuthClientOptions _authOptionsForPlatform() {
    if (!kIsWeb) {
      return const FlutterAuthClientOptions();
    }

    final sessionKey = _sessionStorageKey(AppConfig.effectiveSupabaseUrl);

    // Web preview: never allow supabase_flutter to pick SharedPreferences-based
    // defaults (session + PKCE). detectSessionInUri stays off — email/password
    // only, no OAuth deep links on GitHub Pages.
    return FlutterAuthClientOptions(
      detectSessionInUri: false,
      localStorage: WebBrowserLocalStorage(persistSessionKey: sessionKey),
      pkceAsyncStorage: InMemoryGotrueAsyncStorage(),
    );
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    final validation = StartupConfigValidation.validate(
      url: AppConfig.effectiveSupabaseUrl,
      key: AppConfig.effectiveSupabaseAnonKey,
    );
    if (!validation.isOk) {
      throw StateError(validation.userMessage);
    }

    final anonKey = AppConfig.effectiveSupabaseAnonKey;

    try {
      await Supabase.initialize(
        url: AppConfig.effectiveSupabaseUrl,
        publishableKey: anonKey,
        anonKey: anonKey,
        authOptions: _authOptionsForPlatform(),
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StateError(
          'Supabase initialization failed.\n'
          'Verify SUPABASE_URL and SUPABASE_ANON_KEY (public anon/publishable '
          'key only).\n'
          'Technical detail: $error',
        ),
        stackTrace,
      );
    }

    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
