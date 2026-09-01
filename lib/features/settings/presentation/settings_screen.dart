import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../sync/providers/sync_providers.dart';
import '../../../sync/sync_bootstrap.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/fcm_providers.dart';
import 'notification_preferences_screen.dart';
import 'pending_transactions_screen.dart';
import 'staff_management_screen.dart';
import 'sync_conflicts_screen.dart';

/// Settings: profile, offline queue, notification prefs, staff mgmt
/// (Owner), and sync conflicts (Manager/Owner).
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
          final canManageStaff = profile.role.canManageStaff;
          final canViewReports = profile.role.canViewReports;

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
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text(AppStrings.notificationPreferences),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationPreferencesScreen(),
                    ),
                  ),
                ),
              ),
              if (canManageStaff)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text(AppStrings.staffManagement),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const StaffManagementScreen(),
                      ),
                    ),
                  ),
                ),
              if (canViewReports)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.sync_problem_outlined),
                    title: const Text(AppStrings.syncConflicts),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SyncConflictsScreen(),
                      ),
                    ),
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
                  try {
                    await ref
                        .read(fcmServiceProvider)
                        .unregisterTokenIfAvailable();
                  } finally {
                    await ref.read(authRepositoryProvider).signOut();
                  }
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
