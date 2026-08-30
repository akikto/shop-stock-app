import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/fcm_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Registers the device FCM token once a profile is loaded.
final fcmRegistrationProvider = Provider.autoDispose<void>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  if (profile == null || !profile.isActive) return;
  FcmService().registerTokenIfAvailable();
});
