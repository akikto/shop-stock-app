import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/services/in_memory_gotrue_storage.dart';

void main() {
  group('InMemoryGotrueAsyncStorage', () {
    test('stores and retrieves PKCE values in memory', () async {
      final storage = InMemoryGotrueAsyncStorage();

      await storage.setItem(key: 'verifier', value: 'abc');
      expect(await storage.getItem(key: 'verifier'), 'abc');

      await storage.removeItem(key: 'verifier');
      expect(await storage.getItem(key: 'verifier'), isNull);
    });
  });
}
