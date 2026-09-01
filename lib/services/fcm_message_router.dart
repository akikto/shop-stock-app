import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../features/home/presentation/notifications_screen.dart';

/// Routes FCM notification taps and foreground messages to [NotificationsScreen].
class FcmMessageRouter {
  FcmMessageRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _pendingOpen = false;
  static bool _screenOpen = false;

  /// Opens the notifications inbox once the root navigator is available.
  static Future<void> openNotifications() async {
    if (_screenOpen) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingOpen = true;
      return;
    }

    _pendingOpen = false;
    _screenOpen = true;
    try {
      await navigator.push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'notifications'),
          builder: (_) => const NotificationsScreen(),
        ),
      );
    } finally {
      _screenOpen = false;
    }
  }

  /// Call after the protected shell mounts so terminated-app taps can navigate.
  static void flushPendingNavigation() {
    if (_pendingOpen) {
      openNotifications();
    }
  }

  static void handleMessageOpened(RemoteMessage _) {
    openNotifications();
  }

  static void showForegroundNotification(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final body = message.notification?.body?.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          body != null && body.isNotEmpty
              ? body
              : AppStrings.notifications,
        ),
        action: SnackBarAction(
          label: AppStrings.viewNotifications,
          onPressed: openNotifications,
        ),
      ),
    );
  }

  @visibleForTesting
  static void resetForTest() {
    _pendingOpen = false;
    _screenOpen = false;
  }
}
