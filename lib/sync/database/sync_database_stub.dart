/// Web / non-IO stub — offline sync is Android-native only.
class SyncDatabase {
  SyncDatabase();

  SyncDatabase.forTesting(dynamic executor);

  Future<void> close() async {}

  static Future<SyncDatabase> open() async => SyncDatabase();
}
