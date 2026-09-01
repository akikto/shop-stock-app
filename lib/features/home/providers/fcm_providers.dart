import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/fcm_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Shared [FcmService] instance for the app session.
final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService();
  ref.onDispose(() {
    unawaited(service.disposeMessagingSubscriptions());
  });
  return service;
});

/// Registers the device FCM token once an active profile is loaded.
final fcmRegistrationProvider = Provider.autoDispose<void>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  if (profile == null || !profile.isActive) return;

  final service = ref.watch(fcmServiceProvider);
  unawaited(service.registerTokenIfAvailable());
  unawaited(service.configureMessageHandlers());
});
