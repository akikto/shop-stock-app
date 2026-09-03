/// Result of validating compile-time Supabase configuration.
enum StartupConfigStatus {
  ok,
  missing,
  invalidUrl,
  secretKeyUsed,
}

class StartupConfigValidation {
  const StartupConfigValidation._({
    required this.status,
    this.detail,
  });

  final StartupConfigStatus status;
  final String? detail;

  bool get isOk => status == StartupConfigStatus.ok;

  static StartupConfigValidation validate({
    required String url,
    required String key,
  }) {
    if (url.isEmpty || key.isEmpty) {
      return const StartupConfigValidation._(
        status: StartupConfigStatus.missing,
        detail:
            'SUPABASE_URL and SUPABASE_ANON_KEY were not passed at build time.\n'
            'Local: flutter run --dart-define-from-file=config/config.json\n'
            'GitHub Pages: set repository secrets SUPABASE_URL and '
            'SUPABASE_ANON_KEY, then redeploy.',
      );
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return StartupConfigValidation._(
        status: StartupConfigStatus.invalidUrl,
        detail:
            'SUPABASE_URL must be a full URL such as '
            'https://YOUR-PROJECT-REF.supabase.co\nGot: "$url"',
      );
    }

    if (key.startsWith('sb_secret_') || key.contains('service_role')) {
      return const StartupConfigValidation._(
        status: StartupConfigStatus.secretKeyUsed,
        detail:
            'SUPABASE_ANON_KEY must be the public anon/publishable key only. '
            'Never use the service_role key in the Flutter app.',
      );
    }

    return const StartupConfigValidation._(status: StartupConfigStatus.ok);
  }

  String get userMessage {
    switch (status) {
      case StartupConfigStatus.ok:
        return '';
      case StartupConfigStatus.missing:
      case StartupConfigStatus.invalidUrl:
      case StartupConfigStatus.secretKeyUsed:
        return detail ?? 'Invalid Supabase configuration.';
    }
  }
}

String? _firstStackFrame(StackTrace? stackTrace) {
  if (stackTrace == null) return null;
  for (final line in stackTrace.toString().split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#0') && trimmed.contains('main.')) {
      continue;
    }
    if (trimmed.startsWith('#')) return trimmed;
  }
  return null;
}

/// Formats startup failures for the preview error screen.
String formatStartupFailure(Object error, [StackTrace? stackTrace]) {
  if (error is StateError) {
    return error.message;
  }
  final message = error.toString();
  if (message.contains('Null check operator used on a null value')) {
    final stackHint = _firstStackFrame(stackTrace);
    return 'Startup failed with a null-check crash on web.\n'
        'Common causes: stale cached preview bundle, missing GitHub secrets, '
        'or a plugin initializing before Supabase.\n'
        'Try a hard refresh (or incognito). Confirm repository secrets '
        'SUPABASE_URL + SUPABASE_ANON_KEY are set, then redeploy.\n'
        '${stackHint != null ? 'First stack frame: $stackHint' : ''}';
  }
  final buffer = StringBuffer(message);
  if (stackTrace != null && stackTrace.toString().trim().isNotEmpty) {
    buffer
      ..writeln()
      ..writeln()
      ..write(stackTrace);
  }
  return buffer.toString();
}
