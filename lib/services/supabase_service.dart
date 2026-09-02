import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';

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

    // Web preview: skip AppLinks deep-link handling at startup. The browser
    // preview uses email/password only, and app_links can throw during
    // SupabaseAuth.initialize on GitHub Pages (null-check in getInitialLink).
    // PKCE verifier storage stays in-memory on web — fine for this login flow.
    final authOptions = kIsWeb
        ? const FlutterAuthClientOptions(
            detectSessionInUri: false,
            pkceAsyncStorage: MemoryAuthAsyncStorage(),
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
