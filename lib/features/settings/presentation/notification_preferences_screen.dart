import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../repositories/staff_repository.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/staff_providers.dart';

/// Toggle which in-app notification types the signed-in user receives.
class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notificationPreferences)),
      body: prefsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(notificationPreferencesProvider),
        ),
        data: (prefs) => ListView(
          children: [
            SwitchListTile(
              title: const Text(AppStrings.notifySales),
              value: prefs.notifySale,
              onChanged: _saving
                  ? null
                  : (value) => _save(prefs.copyWith(notifySale: value)),
            ),
            SwitchListTile(
              title: const Text(AppStrings.notifyStockIn),
              value: prefs.notifyStockIn,
              onChanged: _saving
                  ? null
                  : (value) => _save(prefs.copyWith(notifyStockIn: value)),
            ),
            SwitchListTile(
              title: const Text(AppStrings.notifyStockAdjustment),
              value: prefs.notifyStockAdjustment,
              onChanged: _saving
                  ? null
                  : (value) =>
                      _save(prefs.copyWith(notifyStockAdjustment: value)),
            ),
            SwitchListTile(
              title: const Text(AppStrings.notifyLowStock),
              value: prefs.notifyLowStock,
              onChanged: _saving
                  ? null
                  : (value) => _save(prefs.copyWith(notifyLowStock: value)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(NotificationPreferences prefs) async {
    setState(() => _saving = true);
    try {
      await ref.read(staffRepositoryProvider).saveNotificationPreferences(prefs);
      ref.invalidate(notificationPreferencesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.preferencesSaved)),
        );
      }
    } on StaffException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
