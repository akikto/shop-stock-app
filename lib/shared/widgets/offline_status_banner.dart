import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../sync/providers/sync_providers.dart';
import '../../sync/sync_bootstrap.dart';

/// Offline / syncing status strip shown above the protected shell.
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SyncBootstrap.isInitialized) return const SizedBox.shrink();

    final online = ref.watch(connectivityStatusProvider).value ?? true;
    final syncState = ref.watch(syncControllerProvider);
    final pendingCount = ref.watch(pendingTransactionCountProvider).value ?? 0;

    if (online && !syncState.isSyncing && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    Color bg;
    String message;
    if (!online) {
      bg = theme.colorScheme.errorContainer;
      message = AppStrings.offlineMode;
    } else if (syncState.isSyncing) {
      bg = theme.colorScheme.primaryContainer;
      message = AppStrings.syncing;
    } else if (pendingCount > 0) {
      bg = theme.colorScheme.tertiaryContainer;
      message = '${AppStrings.pendingSync}: $pendingCount';
    } else {
      return const SizedBox.shrink();
    }

    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            if (online && pendingCount > 0)
              TextButton(
                onPressed: () =>
                    ref.read(syncControllerProvider.notifier).requestSync(),
                child: const Text(AppStrings.retrySync),
              ),
          ],
        ),
      ),
    );
  }
}
