/// Result of a sale / stock-in / adjustment write from the UI layer.
enum TransactionWriteResult {
  /// RPC completed on the server immediately.
  synced,

  /// Stored in the local offline queue; will sync when online.
  queuedLocally,
}
