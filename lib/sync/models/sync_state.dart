class SyncState {
  const SyncState({
    this.isSyncing = false,
    this.lastError,
    this.lastSuccessfulSyncAt,
  });

  final bool isSyncing;
  final String? lastError;
  final DateTime? lastSuccessfulSyncAt;

  SyncState copyWith({
    bool? isSyncing,
    String? lastError,
    bool clearLastError = false,
    DateTime? lastSuccessfulSyncAt,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
    );
  }
}
