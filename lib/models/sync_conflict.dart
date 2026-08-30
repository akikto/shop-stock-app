/// Offline sync conflict logged server-side for manager/owner review.
class SyncConflict {
  const SyncConflict({
    required this.id,
    required this.deviceTxnId,
    required this.actorId,
    required this.action,
    required this.resolved,
    required this.createdAt,
    this.productId,
    this.details = const {},
  });

  final String id;
  final String deviceTxnId;
  final String actorId;
  final String action;
  final String? productId;
  final Map<String, dynamic> details;
  final bool resolved;
  final DateTime createdAt;

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'] as String,
      deviceTxnId: json['device_txn_id'] as String,
      actorId: json['actor_id'] as String,
      action: json['action'] as String,
      productId: json['product_id'] as String?,
      details: json['details'] is Map
          ? Map<String, dynamic>.from(json['details'] as Map)
          : const {},
      resolved: json['resolved'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
