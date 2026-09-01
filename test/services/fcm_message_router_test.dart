import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/services/fcm_message_router.dart';

void main() {
  setUp(FcmMessageRouter.resetForTest);

  test('flushPendingNavigation is safe when navigator is absent', () {
    expect(() => FcmMessageRouter.flushPendingNavigation(), returnsNormally);
  });
}
