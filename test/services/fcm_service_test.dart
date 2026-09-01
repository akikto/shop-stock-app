import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/services/fcm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RecordingClient extends Fake implements SupabaseClient {
  _RecordingClient({this.userId = 'user-1'});

  final String? userId;
  int rpcCalls = 0;
  String? lastRpcToken;

  @override
  GoTrueClient get auth => _FakeAuth(userId);

  @override
  Future<dynamic> rpc(
    String fn, {
    Map<String, dynamic>? params,
    dynamic options,
  }) async {
    rpcCalls++;
    lastRpcToken = params?['p_token'] as String?;
    return null;
  }
}

class _FakeAuth extends Fake implements GoTrueClient {
  _FakeAuth(this.userId);

  final String? userId;

  @override
  User? get currentUser => userId == null
      ? null
      : User(
          id: userId!,
          appMetadata: const <String, dynamic>{},
          userMetadata: const <String, dynamic>{},
          aud: 'authenticated',
          createdAt: '2026-01-01T00:00:00Z',
        );
}

void main() {
  group('FcmService', () {
    test('registerTokenForTest skips duplicate RPC for same token', () async {
      final client = _RecordingClient();
      final service = FcmService(client: client);

      await service.registerTokenForTest('token-a');
      await service.registerTokenForTest('token-a');
      await service.registerTokenForTest('token-b');

      expect(client.rpcCalls, 2);
      expect(service.lastRegisteredTokenForTest, 'token-b');
    });

    test('registerTokenIfAvailable is no-op when Firebase is not initialized',
        () async {
      final client = _RecordingClient();
      final service = FcmService(client: client);

      await service.registerTokenIfAvailable();

      expect(client.rpcCalls, 0);
      expect(service.hasTokenRefreshListener, isFalse);
    });

    test('unregisterTokenIfAvailable is no-op when Firebase is not initialized',
        () async {
      final client = _RecordingClient();
      final service = FcmService(client: client);

      await service.unregisterTokenIfAvailable();

      expect(client.rpcCalls, 0);
    });

    test('attachTokenRefreshListenerForTest only attaches once', () async {
      final client = _RecordingClient();
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
