import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../sync/providers/sync_providers.dart';
import '../../../sync/sync_bootstrap.dart';
import 'pending_transactions_screen.dart';

/// Settings screen. Phase 0 scope: shows the signed-in user's name and
/// role, and provides Logout — the only fully "real" action on this
/// screen for now. Language toggle and other preferences are added in
/// a later phase.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final pendingCount = SyncBootstrap.isInitialized
        ? ref.watch(pendingTransactionCountProvider).value ?? 0
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: profileAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (profile) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(profile.name),
                  subtitle: Text('${AppStrings.role}: ${profile.role.name}'),
                ),
              ),
              if (pendingCount > 0)
                Card(
                  child: ListTile(
                    leading: Badge(
                      label: Text('$pendingCount'),
                      child: const Icon(Icons.cloud_upload_outlined),
                    ),
                    title: const Text(AppStrings.pendingTransactions),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const PendingTransactionsScreen()),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.logout),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
