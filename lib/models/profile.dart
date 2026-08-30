import 'user_role.dart';

/// Maps 1:1 to a row in the `profiles` table.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
  });

  final String id;
  final String name;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: UserRole.fromString(json['role'] as String),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role.name,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
