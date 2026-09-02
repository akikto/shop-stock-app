import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
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

  static Future<void> initialize() async {
    if (_initialized) return;
    AppConfig.assertConfigured();

    // Web preview: avoid shared_preferences during Supabase init. On many
    // Flutter web builds supabase_flutter falls back to SharedPreferences
    // (when dart.library.js_interop is false), which can throw a null-check
    // at startup. Use browser localStorage + in-memory PKCE storage instead.
    final sessionKey =
        'sb-${Uri.parse(AppConfig.effectiveSupabaseUrl).host.split('.').first}-auth-token';

    final authOptions = kIsWeb
        ? FlutterAuthClientOptions(
            detectSessionInUri: false,
            localStorage: WebBrowserLocalStorage(
              persistSessionKey: sessionKey,
            ),
            pkceAsyncStorage: InMemoryGotrueAsyncStorage(),
          )
        : const FlutterAuthClientOptions();

    try {
      await Supabase.initialize(
        url: AppConfig.effectiveSupabaseUrl,
        publishableKey: AppConfig.effectiveSupabaseAnonKey,
        authOptions: authOptions,
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StateError(
          'Supabase failed to initialize. '
          'Check SUPABASE_URL and SUPABASE_ANON_KEY (public anon/publishable '
          'key only). Underlying error: $error',
        ),
        stackTrace,
      );
    }

    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
