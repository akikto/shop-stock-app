/// Mirrors the `user_role` Postgres enum defined in
/// supabase/migrations/0001_initial_schema.sql. Keep in sync manually —
/// there are only three values and they change rarely.
enum UserRole {
  owner,
  manager,
  staff;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.staff,
    );
  }

  bool get canManageStaff => this == UserRole.owner;

  bool get canAdjustStock => this == UserRole.owner || this == UserRole.manager;

  bool get canViewReports => this == UserRole.owner || this == UserRole.manager;

  bool get canManageProducts => this == UserRole.owner || this == UserRole.manager;
}
