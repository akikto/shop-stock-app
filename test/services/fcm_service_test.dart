import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shop_stock_app/services/fcm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<Object?> {}

_MockPostgrestFilterBuilder _completedRpc() {
  final builder = _MockPostgrestFilterBuilder();
  when(
    () => builder.then<void>(any(), onError: any(named: 'onError')),
  ).thenAnswer((_) => Future<void>.value());
  return builder;
}

void main() {
  late _MockSupabaseClient client;
  late _MockGoTrueClient auth;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(null);
  });

  group('FcmService', () {
    test('registerTokenForTest skips duplicate RPC for same token', () async {
      var rpcCalls = 0;
      when(
        () => client.rpc<Object?>(
          any(),
          params: any(named: 'params'),
        ),
      ).thenAnswer((invocation) {
        rpcCalls++;
        return _completedRpc();
      });

      final service = FcmService(client: client);
      await service.registerTokenForTest('token-a');
      await service.registerTokenForTest('token-a');
      await service.registerTokenForTest('token-b');

      expect(rpcCalls, 2);
      expect(service.lastRegisteredTokenForTest, 'token-b');
    });

    test('registerTokenIfAvailable is no-op when Firebase is not initialized',
        () async {
      final service = FcmService(client: client);

      await service.registerTokenIfAvailable();

      verifyNever(
        () => client.rpc<Object?>(any(), params: any(named: 'params')),
      );
      expect(service.hasTokenRefreshListener, isFalse);
    });

    test('unregisterTokenIfAvailable is no-op when Firebase is not initialized',
        () async {
      final service = FcmService(client: client);

      await service.unregisterTokenIfAvailable();

      verifyNever(
        () => client.rpc<Object?>(any(), params: any(named: 'params')),
      );
    });

    test('attachTokenRefreshListenerForTest only attaches once', () async {
      when(
        () => client.rpc<Object?>(any(), params: any(named: 'params')),
      ).thenAnswer((_) => _completedRpc());

      final service = FcmService(client: client);
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
