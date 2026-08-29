import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../../models/sync_conflict.dart';
import '../../../repositories/staff_repository.dart';
import '../../../repositories/sync_conflict_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return SupabaseStaffRepository();
});

final syncConflictRepositoryProvider = Provider<SyncConflictRepository>((ref) {
  return SupabaseSyncConflictRepository();
});

final staffListProvider = FutureProvider.autoDispose<List<Profile>>((ref) async {
  final repo = ref.watch(staffRepositoryProvider);
  return repo.listStaff();
});

final notificationPreferencesProvider =
    FutureProvider.autoDispose<NotificationPreferences>((ref) async {
  final repo = ref.watch(staffRepositoryProvider);
  return repo.getNotificationPreferences();
});

final syncConflictsProvider =
    FutureProvider.autoDispose<List<SyncConflict>>((ref) async {
  final repo = ref.watch(syncConflictRepositoryProvider);
  return repo.listConflicts();
});
