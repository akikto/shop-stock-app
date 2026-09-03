import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/sync_bootstrap.dart';

/// Android (IO): open Drift DB and wire sync providers before runApp.
Future<ProviderContainer> createAppContainer() async {
  return SyncBootstrap.createContainer();
}
