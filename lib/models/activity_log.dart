/// Maps to a row in the `activity_logs` table (immutable audit trail).
/// `actorName` is not a column on this table — it's resolved
/// separately via `list_profiles_public()` and attached client-side,
/// since activity_logs only stores `actor_id` (a uuid).
class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.actorId,
    required this.action,
    required this.details,
    required this.createdAt,
    this.actorName,
    this.referenceTable,
    this.referenceId,
  });

  final String id;
  final String actorId;
  final String? actorName;
  final String action;
  final String? referenceTable;
  final String? referenceId;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      action: json['action'] as String,
      referenceTable: json['reference_table'] as String?,
      referenceId: json['reference_id'] as String?,
      details: (json['details'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  ActivityLog copyWithActorName(String? name) {
    return ActivityLog(
      id: id,
      actorId: actorId,
      actorName: name,
      action: action,
      referenceTable: referenceTable,
      referenceId: referenceId,
      details: details,
      createdAt: createdAt,
    );
  }

  /// Product name, if present in details — every Phase 1/2 action logs
  /// this under a consistent key.
  String? get productName => details['product_name'] as String?;
}
