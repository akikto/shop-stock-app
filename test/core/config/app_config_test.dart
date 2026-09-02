import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('effectiveSupabaseUrl trims surrounding whitespace', () {
      expect(AppConfig.effectiveSupabaseUrl, AppConfig.supabaseUrl.trim());
    });

    test('effectiveSupabaseAnonKey trims surrounding whitespace', () {
      expect(
        AppConfig.effectiveSupabaseAnonKey,
        AppConfig.supabaseAnonKey.trim(),
      );
    });

    test(
      'assertConfigured throws when dart-defines are missing in test env',
      () {
        expect(
          () => AppConfig.assertConfigured(),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
