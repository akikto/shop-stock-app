import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/fcm_background_handler.dart';
import '../services/fcm_service.dart';

/// Android (and other IO platforms): register FCM when Firebase is configured.
Future<void> bootstrapFcm() async {
  await FcmService.initialize();
  if (FcmService.isInitialized) {
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundMessageHandler);
  }
}
