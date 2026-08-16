/// Maps to a row in the `notifications` table.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String message;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
