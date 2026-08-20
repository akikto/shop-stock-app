import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';

/// Settings screen. Phase 0 scope: shows the signed-in user's name and
/// role, and provides Logout — the only fully "real" action on this
/// screen for now. Language toggle and other preferences are added in
/// a later phase.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

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
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.logout),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
