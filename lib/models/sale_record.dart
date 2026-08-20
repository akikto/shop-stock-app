/// Maps to a row in the `sales` table, returned by the `record_sale()`
/// RPC function (migration 0007).
class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.productId,
    required this.userId,
    required this.quantity,
    required this.unitPriceAtSale,
    required this.totalAmount,
    required this.deviceTxnId,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String userId;
  final num quantity;
  final num unitPriceAtSale;
  final num totalAmount;
  final String deviceTxnId;
  final DateTime createdAt;

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      userId: json['user_id'] as String,
      quantity: json['quantity'] as num,
      unitPriceAtSale: json['unit_price_at_sale'] as num,
      totalAmount: json['total_amount'] as num,
      deviceTxnId: json['device_txn_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
