import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fcm_message_router.dart';
import 'supabase_service.dart';

/// Registers FCM device tokens with Supabase when Firebase is configured.
/// On web or when google-services.json is absent, this is a safe no-op.
class FcmService {
  FcmService({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;
  SupabaseClient get _client => _clientOverride ?? SupabaseService.client;

  static bool _initialized = false;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  String? _lastRegisteredToken;
  bool _messageHandlersConfigured = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (_) {
      // Firebase not configured — in-app notifications still work.
    }
  }

  static bool get isInitialized => _initialized;

  /// Registers the current device token and ensures a single refresh listener.
  Future<void> registerTokenIfAvailable() async {
    if (!_initialized || kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _registerTokenWithServer(token);
      _ensureTokenRefreshListener();
    } catch (_) {
      // Push is best-effort; in-app notifications remain authoritative.
    }
  }

  /// Removes the current device token for the authenticated user (logout).
  Future<void> unregisterTokenIfAvailable() async {
    if (!_initialized || kIsWeb) return;
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _client
            .from('fcm_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);
      }
      _lastRegisteredToken = null;
    } catch (_) {
      // Best-effort cleanup.
    } finally {
      await disposeMessagingSubscriptions();
    }
  }

  /// Wires foreground, background-open, and terminated notification handling.
  Future<void> configureMessageHandlers() async {
    if (!_initialized || kIsWeb || _messageHandlersConfigured) return;
    _messageHandlersConfigured = true;

    try {
      final messaging = FirebaseMessaging.instance;

      _foregroundSub = FirebaseMessaging.onMessage.listen(
        FcmMessageRouter.showForegroundNotification,
      );
      _openedAppSub =
          FirebaseMessaging.onMessageOpenedApp.listen(FcmMessageRouter.handleMessageOpened);

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        FcmMessageRouter.handleMessageOpened(initial);
      }
    } catch (_) {
      _messageHandlersConfigured = false;
    }
  }

  Future<void> disposeMessagingSubscriptions() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _foregroundSub?.cancel();
    _foregroundSub = null;
    await _openedAppSub?.cancel();
    _openedAppSub = null;
    _messageHandlersConfigured = false;
  }

  void _ensureTokenRefreshListener() {
    if (_tokenRefreshSub != null) return;
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      unawaited(_registerTokenWithServer(newToken));
    });
  }

  /// Test hook: binds [stream] instead of Firebase when verifying listener lifecycle.
  @visibleForTesting
  bool attachTokenRefreshListenerForTest(Stream<String> stream) {
    if (_tokenRefreshSub != null) return false;
    _tokenRefreshSub = stream.listen((newToken) {
      unawaited(_registerTokenWithServer(newToken));
    });
    return true;
  }

  Future<void> _registerTokenWithServer(String token) async {
    if (token.isEmpty) return;
    if (_lastRegisteredToken == token) return;
    await _client.rpc('register_fcm_token', params: {
      'p_token': token,
      'p_platform': defaultTargetPlatform.name,
    });
    _lastRegisteredToken = token;
  }

  @visibleForTesting
  Future<void> registerTokenForTest(String token) => _registerTokenWithServer(token);

  @visibleForTesting
  bool get hasTokenRefreshListener => _tokenRefreshSub != null;

  @visibleForTesting
  String? get lastRegisteredTokenForTest => _lastRegisteredToken;

  @visibleForTesting
  bool get messageHandlersConfiguredForTest => _messageHandlersConfigured;
}
