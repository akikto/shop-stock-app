enum PendingTransactionStatus {
  pending,
  syncing,
  synced,
  failed;

  String get storageValue => name;

  static PendingTransactionStatus fromStorage(String value) {
    return PendingTransactionStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PendingTransactionStatus.pending,
    );
  }
}
