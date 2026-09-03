import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/config/startup_config.dart';

void main() {
  group('StartupConfigValidation', () {
    test('ok for valid url and key', () {
      final result = StartupConfigValidation.validate(
        url: 'https://example.supabase.co',
        key: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9',
      );
      expect(result.isOk, isTrue);
    });

    test('missing when url or key empty', () {
      expect(
        StartupConfigValidation.validate(url: '', key: 'abc').status,
        StartupConfigStatus.missing,
      );
      expect(
        StartupConfigValidation.validate(
          url: 'https://example.supabase.co',
          key: '',
        ).status,
        StartupConfigStatus.missing,
      );
    });

    test('invalidUrl when host missing', () {
      expect(
        StartupConfigValidation.validate(url: 'not-a-url', key: 'abc').status,
        StartupConfigStatus.invalidUrl,
      );
    });

    test('secretKeyUsed for sb_secret keys', () {
      expect(
        StartupConfigValidation.validate(
          url: 'https://example.supabase.co',
          key: 'sb_secret_abc',
        ).status,
        StartupConfigStatus.secretKeyUsed,
      );
    });
  });

  group('formatStartupFailure', () {
    test('expands null-check errors with actionable text', () {
      final text = formatStartupFailure(
        'Null check operator used on a null value',
        StackTrace.fromString('#1      Supabase.initialize (package:supabase_flutter/...)\n'),
      );
      expect(text, contains('null-check crash'));
      expect(text, contains('Supabase.initialize'));
    });
  });
}
