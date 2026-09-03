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

  group('FCM bootstrap is excluded from web builds', () {
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
