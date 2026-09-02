// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'package:supabase_flutter/supabase_flutter.dart';

/// dart2js web: persist sessions via [window.localStorage].
class WebBrowserLocalStorage extends LocalStorage {
  WebBrowserLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;

  html.Storage get _storage => html.window.localStorage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      _storage[persistSessionKey] != null;

  @override
  Future<String?> accessToken() async => _storage[persistSessionKey];

  @override
  Future<void> removePersistedSession() async {
    _storage.remove(persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    _storage[persistSessionKey] = persistSessionString;
  }
}
