import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/sync_conflict.dart';
import '../../../repositories/sync_conflict_repository.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/staff_providers.dart';

/// Manager/Owner review of offline sync conflicts.
class SyncConflictsScreen extends ConsumerWidget {
  const SyncConflictsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictsAsync = ref.watch(syncConflictsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.syncConflicts)),
      body: conflictsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(syncConflictsProvider),
        ),
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return const Center(child: Text(AppStrings.noSyncConflicts));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(syncConflictsProvider),
            child: ListView.separated(
              itemCount: conflicts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _ConflictTile(
                conflict: conflicts[index],
                onResolve: () => _resolve(context, ref, conflicts[index].id),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _resolve(
      BuildContext context, WidgetRef ref, String conflictId) async {
    try {
      await ref.read(syncConflictRepositoryProvider).resolveConflict(conflictId);
      ref.invalidate(syncConflictsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.conflictResolved)),
        );
      }
    } on SyncConflictException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _ConflictTile extends StatelessWidget {
  const _ConflictTile({required this.conflict, required this.onResolve});

  final SyncConflict conflict;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final details = conflict.details.isNotEmpty
        ? conflict.details.entries.map((e) => '${e.key}: ${e.value}').join(', ')
        : '';

    return ListTile(
      leading: Icon(
        conflict.resolved ? Icons.check_circle_outline : Icons.error_outline,
        color: conflict.resolved ? Colors.green : Colors.orange,
      ),
      title: Text(conflict.action),
      subtitle: Text(
        '${conflict.createdAt.toLocal()}\n$details',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: conflict.resolved
          ? null
          : TextButton(
              onPressed: onResolve,
              child: const Text(AppStrings.markResolved),
            ),
    );
  }
}
