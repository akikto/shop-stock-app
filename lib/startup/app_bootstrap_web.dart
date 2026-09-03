import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web preview: no offline sync / Drift — plain Riverpod container only.
Future<ProviderContainer> createAppContainer() async {
  return ProviderContainer();
}
