import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('web Supabase auth options (GitHub Pages preview)', () {
    late String source;

    setUpAll(() {
      source = File('lib/services/supabase_service.dart').readAsStringSync();
    });

    test('uses EmptyLocalStorage and implicit auth on web', () {
      expect(source, contains('AuthFlowType.implicit'));
      expect(source, contains('EmptyLocalStorage'));
      expect(source, contains('detectSessionInUri: false'));
      expect(source, contains('InMemoryGotrueAsyncStorage'));
    });

    test('does not reference WebBrowserLocalStorage in web auth path', () {
      expect(source, isNot(contains('WebBrowserLocalStorage(')));
    });
  });

  group('app bootstrap excludes sync on web builds', () {
    test('main.dart uses conditional app bootstrap import', () {
      final mainSource = File('lib/main.dart').readAsStringSync();
      expect(mainSource, contains('app_bootstrap_web.dart'));
      expect(mainSource, contains('app_bootstrap_io.dart'));
      expect(mainSource, contains('createAppContainer'));
      expect(mainSource, isNot(contains('SyncBootstrap.initialize')));
    });

    test('web bootstrap does not import sync_bootstrap', () {
      final webBootstrap =
          File('lib/startup/app_bootstrap_web.dart').readAsStringSync();
      expect(webBootstrap, isNot(contains('sync_bootstrap')));
      expect(webBootstrap, isNot(contains('SyncBootstrap')));
    });

    test('sync bootstrap uses ProviderContainer overrides at construction', () {
      final source = File('lib/sync/sync_bootstrap.dart').readAsStringSync();
      expect(source, contains('ProviderContainer('));
      expect(source, contains('overrides:'));
      expect(source, isNot(contains('updateOverrides'));
    });
  });
    test('main.dart uses conditional FCM bootstrap import', () {
      final mainSource = File('lib/main.dart').readAsStringSync();
      expect(mainSource, contains('fcm_bootstrap_stub.dart'));
      expect(mainSource, contains('fcm_bootstrap_mobile.dart'));
      expect(mainSource, isNot(contains('firebase_messaging')));
    });

    test('web stub has no Firebase imports', () {
      final stub = File('lib/startup/fcm_bootstrap_stub.dart').readAsStringSync();
      expect(stub, isNot(contains("import 'package:firebase")));
      expect(stub, isNot(contains('import "package:firebase')));
    });
  });
}
