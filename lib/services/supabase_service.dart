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

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );

    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
