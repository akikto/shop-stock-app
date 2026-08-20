import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/models/profile.dart';
import 'package:shop_stock_app/models/user_role.dart';

void main() {
  group('UserRole', () {
    test('fromString parses known values', () {
      expect(UserRole.fromString('owner'), UserRole.owner);
      expect(UserRole.fromString('manager'), UserRole.manager);
      expect(UserRole.fromString('staff'), UserRole.staff);
    });

    test(
        'fromString defaults to staff for unknown value (fail-safe, least privilege)',
        () {
      expect(UserRole.fromString('something_unexpected'), UserRole.staff);
    });

    test('permission flags reflect intended role boundaries', () {
      expect(UserRole.owner.canManageStaff, isTrue);
      expect(UserRole.manager.canManageStaff, isFalse);
      expect(UserRole.staff.canManageStaff, isFalse);

      expect(UserRole.owner.canAdjustStock, isTrue);
      expect(UserRole.manager.canAdjustStock, isTrue);
      expect(UserRole.staff.canAdjustStock, isFalse);

      expect(UserRole.owner.canViewReports, isTrue);
      expect(UserRole.manager.canViewReports, isTrue);
      expect(UserRole.staff.canViewReports, isFalse);
    });
  });

  group('Profile', () {
    test('fromJson parses a well-formed profile row', () {
      final json = {
        'id': 'user-123',
        'name': 'Karim',
        'phone': '+8801xxxxxxxxx',
        'role': 'manager',
        'is_active': true,
        'created_at': '2026-01-01T10:00:00Z',
        'updated_at': '2026-01-02T10:00:00Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user-123');
      expect(profile.name, 'Karim');
      expect(profile.role, UserRole.manager);
      expect(profile.isActive, isTrue);
    });

    test('toJson round-trips role as its raw string name', () {
      final profile = Profile(
        id: 'user-1',
        name: 'Rahim',
        role: UserRole.staff,
        isActive: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final json = profile.toJson();

      expect(json['role'], 'staff');
      expect(json['is_active'], true);
    });
  });
}
