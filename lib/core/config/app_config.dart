/// Public, client-safe configuration.
///
/// IMPORTANT: only the Supabase *URL* and *anon/public key* belong here.
/// Both are safe to ship inside the app — they are meaningless without
/// the Row Level Security policies that actually govern access.
///
/// The Supabase *service-role* key and any Firebase Cloud Messaging
/// server key must NEVER appear in this file, anywhere else in the
/// Flutter source, or in the compiled app. Those live only on the
/// server side (Supabase Edge Functions / project dashboard secrets).
///
/// Values are supplied at build/run time via `--dart-define-from-file`,
/// e.g.:
///   flutter run --dart-define-from-file=config/config.json
///
/// See config/config.example.json for the expected shape, and the
/// README for setup instructions.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Fails fast at startup if the app was built without configuration,
  /// instead of silently trying to talk to an empty URL.
  static void assertConfigured() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Run with:\n'
        '  flutter run --dart-define-from-file=config/config.json\n'
        'See README.md for setup instructions.',
      );
    }
  }
}
