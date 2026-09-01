import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/responsive/mobile_frame.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/fcm_background_handler.dart';
import 'services/fcm_service.dart';
import 'services/supabase_service.dart';
import 'sync/sync_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fails fast with a clear error if config wasn't supplied — see
  // core/config/app_config.dart and README.md.
  await SupabaseService.initialize();
  await FcmService.initialize();

  if (FcmService.isInitialized) {
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundMessageHandler);
  }

  final container = ProviderContainer();
  await SyncBootstrap.initialize(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ShopStockApp(),
    ),
  );
}

class ShopStockApp extends ConsumerWidget {
  const ShopStockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Shop Stock & Sales',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      // MobileFrame is a no-op on real phone-width viewports (including
      // the native Android app) — it only letterboxes wide desktop
      // browser windows so the web preview looks like a phone. See
      // lib/core/responsive/mobile_frame.dart.
      builder: (context, child) =>
          MobileFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}
