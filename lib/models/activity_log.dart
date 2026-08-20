/// Maps to a row in the `activity_logs` table.
///
/// Immutable audit trail — written exclusively by SECURITY DEFINER RPC
/// functions (see migrations 0006, 0007), never by a direct client
/// insert. RLS allows SELECT only.
class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.actorId,
    required this.action,
    required this.createdAt,
    this.referenceTable,
    this.referenceId,
    this.details,
  });

  final String id;
  final String actorId;
  final String action;
  final String? referenceTable;
  final String? referenceId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      action: json['action'] as String,
      referenceTable: json['reference_table'] as String?,
      referenceId: json['reference_id'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
