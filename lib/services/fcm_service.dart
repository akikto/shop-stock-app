import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Registers FCM device tokens with Supabase when Firebase is configured.
/// On web or when google-services.json is absent, this is a safe no-op.
class FcmService {
  FcmService({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;
  SupabaseClient get _client => _clientOverride ?? SupabaseService.client;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (_) {
      // Firebase not configured — in-app notifications still work.
    }
  }

  Future<void> registerTokenIfAvailable() async {
    if (!_initialized || kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _client.rpc('register_fcm_token', params: {
        'p_token': token,
        'p_platform': defaultTargetPlatform.name,
      });
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        unawaited(_client.rpc('register_fcm_token', params: {
          'p_token': newToken,
          'p_platform': defaultTargetPlatform.name,
        }));
      });
    } catch (_) {
      // Push is best-effort; in-app notifications remain authoritative.
    }
  }
}
