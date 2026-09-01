import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/services/fcm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RecordingClient extends Fake implements SupabaseClient {
  _RecordingClient({this.userId = 'user-1'});

  final String? userId;
  int rpcCalls = 0;
  int deleteCalls = 0;
  String? lastRpcToken;
  String? lastDeletedToken;

  @override
  GoTrueClient get auth => _FakeAuth(userId);

  @override
  SupabaseQueryBuilder from(String table) {
    if (table != 'fcm_tokens') {
      throw UnimplementedError('Unexpected table: $table');
    }
    return _FakeDeleteBuilder(this);
  }

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
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: '2026-01-01T00:00:00Z',
        );
}

class _FakeDeleteBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeDeleteBuilder(this.client);

  final _RecordingClient client;
  String? _token;

  @override
  PostgrestFilterBuilder delete() {
    client.deleteCalls++;
    return _FakeEqBuilder(client);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEqBuilder extends Fake implements PostgrestFilterBuilder {
  _FakeEqBuilder(this.client);

  final _RecordingClient client;
  final _filters = <String, String>{};

  @override
  PostgrestFilterBuilder eq(String column, Object value) {
    _filters[column] = value.toString();
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> then(
    FutureOr<List<Map<String, dynamic>>> Function(
      List<Map<String, dynamic>> value,
    ) onValue, {
    Function? onError,
  }) {
    if (_filters['token'] != null) {
      client.lastDeletedToken = _filters['token'];
    }
    return Future.value(<Map<String, dynamic>>[]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

      expect(client.deleteCalls, 0);
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
