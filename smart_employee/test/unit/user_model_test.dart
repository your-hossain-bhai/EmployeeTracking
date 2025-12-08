// test/unit/user_model_test.dart
// Unit Tests for User Model
//
// These tests verify the User model's serialization, deserialization,
// and business logic methods.

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_employee/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create a UserModel from JSON', () {
      final json = {
        'id': 'test-id-123',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'role': 'employee',
        'companyId': 'company-123',
        'isActive': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'test-id-123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.role, UserRole.employee);
      expect(user.companyId, 'company-123');
      expect(user.isActive, true);
    });

    test('should convert UserModel to JSON', () {
      final user = UserModel(
        id: 'test-id-123',
        email: 'test@example.com',
        displayName: 'Test User',
        role: UserRole.employee,
        companyId: 'company-123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = user.toJson();

      expect(json['id'], 'test-id-123');
      expect(json['email'], 'test@example.com');
      expect(json['displayName'], 'Test User');
      expect(json['role'], 'employee');
      expect(json['companyId'], 'company-123');
    });

    test('isAdmin should return true for admin role', () {
      final admin = UserModel(
        id: 'admin-id',
        email: 'admin@example.com',
        displayName: 'Admin User',
        role: UserRole.admin,
        companyId: 'company-123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(admin.isAdmin, true);
      expect(admin.isEmployee, false);
    });

    test('isEmployee should return true for employee role', () {
      final employee = UserModel(
        id: 'employee-id',
        email: 'employee@example.com',
        displayName: 'Employee User',
        role: UserRole.employee,
        companyId: 'company-123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(employee.isAdmin, false);
      expect(employee.isEmployee, true);
    });

    test('copyWith should create a new instance with updated fields', () {
      final original = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        role: UserRole.employee,
        companyId: 'company-123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        displayName: 'Updated Name',
        role: UserRole.admin,
      );

      expect(updated.id, original.id);
      expect(updated.email, original.email);
      expect(updated.displayName, 'Updated Name');
      expect(updated.role, UserRole.admin);
    });
  });
}
