import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/profile.dart';
import '../../../models/user_role.dart';
import '../../../repositories/staff_repository.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/staff_providers.dart';

/// Owner-only staff role and activation management.
class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.staffManagement)),
      body: staffAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(staffListProvider),
        ),
        data: (staff) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(staffListProvider),
          child: ListView.separated(
            itemCount: staff.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _StaffTile(profile: staff[index]),
          ),
        ),
      ),
    );
  }
}

class _StaffTile extends ConsumerWidget {
  const _StaffTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?'),
      ),
      title: Text(profile.name),
      subtitle: Text(
        '${profile.role.name} · ${profile.isActive ? AppStrings.active : AppStrings.inactive}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleAction(context, ref, value),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'role', child: Text(AppStrings.changeRole)),
          PopupMenuItem(
            value: profile.isActive ? 'deactivate' : 'activate',
            child: Text(profile.isActive ? AppStrings.deactivateStaff : AppStrings.activateStaff),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(staffRepositoryProvider);
    try {
      if (action == 'role') {
        final newRole = await showDialog<UserRole>(
          context: context,
          builder: (context) => _RolePickerDialog(current: profile.role),
        );
        if (newRole == null || newRole == profile.role) return;
        await repo.updateRole(profile.id, newRole);
      } else if (action == 'deactivate') {
        final confirmed = await _confirm(context, AppStrings.deactivateStaffConfirm);
        if (!confirmed) return;
        await repo.setActive(profile.id, false);
      } else if (action == 'activate') {
        await repo.setActive(profile.id, true);
      }
      ref.invalidate(staffListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.staffUpdated)),
        );
      }
    } on StaffException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<bool> _confirm(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirm),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _RolePickerDialog extends StatefulWidget {
  const _RolePickerDialog({required this.current});

  final UserRole current;

  @override
  State<_RolePickerDialog> createState() => _RolePickerDialogState();
}

class _RolePickerDialogState extends State<_RolePickerDialog> {
  late UserRole _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.changeRole),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: UserRole.values
            .map(
              (role) => RadioListTile<UserRole>(
                title: Text(role.name),
                value: role,
                groupValue: _selected,
                onChanged: (value) {
                  if (value != null) setState(() => _selected = value);
                },
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text(AppStrings.confirm),
        ),
      ],
    );
  }
}
