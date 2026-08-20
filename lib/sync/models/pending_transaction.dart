import 'pending_transaction_status.dart';
import 'pending_transaction_type.dart';

class PendingTransaction {
  const PendingTransaction({
    required this.localId,
    required this.deviceTxnId,
    required this.type,
    required this.productId,
    required this.createdAt,
    required this.status,
    required this.attemptCount,
    this.quantity,
    this.quantityChange,
    this.reason,
    this.lastError,
    this.syncedAt,
    this.productName,
  });

  final int localId;
  final String deviceTxnId;
  final PendingTransactionType type;
  final String productId;
  final num? quantity;
  final num? quantityChange;
  final String? reason;
  final DateTime createdAt;
  final PendingTransactionStatus status;
  final int attemptCount;
  final String? lastError;
  final DateTime? syncedAt;

  /// Resolved from cached product name for display in Settings.
  final String? productName;

  bool get isRetryable =>
      status == PendingTransactionStatus.pending ||
      status == PendingTransactionStatus.failed;
}
