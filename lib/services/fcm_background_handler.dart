import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level background FCM handler. Must not access Flutter UI or Supabase.
@pragma('vm:entry-point')
Future<void> fcmBackgroundMessageHandler(RemoteMessage message) async {
  // Phase 5A: in-app notifications are authoritative; push delivery is Phase 5B.
  // Keep this handler registered so Android does not crash on background messages.
}
