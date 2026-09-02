import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/services/fcm_service.dart';

void main() {
  group('FcmService', () {
    test('registerTokenIfAvailable is no-op when Firebase is not initialized',
        () async {
      final service = FcmService(client: null);

      await service.registerTokenIfAvailable();

      expect(service.hasTokenRefreshListener, isFalse);
    });

    test('unregisterTokenIfAvailable is no-op when Firebase is not initialized',
        () async {
      final service = FcmService(client: null);

      await service.unregisterTokenIfAvailable();
    });

    test('attachTokenRefreshListenerForTest only attaches once', () async {
      final service = FcmService(client: null);
      final controller = StreamController<String>();

      expect(
        service.attachTokenRefreshListenerForTest(controller.stream),
        isTrue,
      );
      expect(
        service.attachTokenRefreshListenerForTest(controller.stream),
        isFalse,
      );
      expect(service.hasTokenRefreshListener, isTrue);

      await controller.close();
    });
  });
}
