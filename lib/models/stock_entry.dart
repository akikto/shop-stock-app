/// Maps to a row in the `stock_entries` table, returned by the
/// `record_stock_in()` RPC function (migration 0007).
class StockEntry {
  const StockEntry({
    required this.id,
    required this.productId,
    required this.userId,
    required this.quantity,
    required this.deviceTxnId,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String userId;
  final num quantity;
  final String deviceTxnId;
  final DateTime createdAt;

  factory StockEntry.fromJson(Map<String, dynamic> json) {
    return StockEntry(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      userId: json['user_id'] as String,
      quantity: json['quantity'] as num,
      deviceTxnId: json['device_txn_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
