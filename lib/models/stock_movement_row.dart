/// One row from `get_stock_movement_report()`.
class StockMovementRow {
  const StockMovementRow({
    required this.movementType,
    required this.referenceId,
    required this.productId,
    required this.productName,
    required this.userId,
    required this.userName,
    required this.quantity,
    required this.quantityChange,
    required this.createdAt,
    this.reason,
    this.amount,
  });

  final String movementType;
  final String referenceId;
  final String productId;
  final String productName;
  final String userId;
  final String userName;
  final num quantity;
  final num quantityChange;
  final String? reason;
  final num? amount;
  final DateTime createdAt;

  factory StockMovementRow.fromJson(Map<String, dynamic> json) {
    return StockMovementRow(
      movementType: json['movement_type'] as String,
      referenceId: json['reference_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? 'Unknown',
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Unknown',
      quantity: json['quantity'] as num? ?? 0,
      quantityChange: json['quantity_change'] as num? ?? 0,
      reason: json['reason'] as String?,
      amount: json['amount'] as num?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
