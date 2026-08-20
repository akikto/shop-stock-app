/// Maps to a row in the `stock_adjustments` table, returned by the
/// `record_adjustment()` RPC function (migration 0007).
class StockAdjustment {
  const StockAdjustment({
    required this.id,
    required this.productId,
    required this.userId,
    required this.quantityChange,
    required this.reason,
    required this.deviceTxnId,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String userId;
  final num quantityChange;
  final String reason;
  final String deviceTxnId;
  final DateTime createdAt;

  factory StockAdjustment.fromJson(Map<String, dynamic> json) {
    return StockAdjustment(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      userId: json['user_id'] as String,
      quantityChange: json['quantity_change'] as num,
      reason: json['reason'] as String,
      deviceTxnId: json['device_txn_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
