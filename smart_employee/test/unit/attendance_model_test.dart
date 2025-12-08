// test/unit/attendance_model_test.dart
// Unit Tests for Attendance Model
//
// These tests verify the Attendance model's serialization,
// business logic, and calculations.

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_employee/models/attendance_model.dart';

void main() {
  group('AttendanceModel', () {
    test('should create an AttendanceModel from JSON', () {
      final json = {
        'id': 'att-123',
        'employeeId': 'emp-456',
        'companyId': 'comp-789',
        'date': '2024-01-01T00:00:00.000Z',
        'checkInTime': '2024-01-01T09:00:00.000Z',
        'checkOutTime': '2024-01-01T18:00:00.000Z',
        'status': 'checkedOut',
        'checkInMethod': 'automatic',
        'isInsideGeofence': true,
        'createdAt': '2024-01-01T09:00:00.000Z',
        'updatedAt': '2024-01-01T18:00:00.000Z',
      };

      final attendance = AttendanceModel.fromJson(json);

      expect(attendance.id, 'att-123');
      expect(attendance.employeeId, 'emp-456');
      expect(attendance.status, AttendanceStatus.checkedOut);
      expect(attendance.checkInMethod, CheckInMethod.automatic);
      expect(attendance.isInsideGeofence, true);
    });

    test('should calculate work duration correctly', () {
      final attendance = AttendanceModel(
        id: 'att-123',
        employeeId: 'emp-456',
        companyId: 'comp-789',
        date: DateTime(2024, 1, 1),
        checkInTime: DateTime(2024, 1, 1, 9, 0),
        checkOutTime: DateTime(2024, 1, 1, 17, 30),
        status: AttendanceStatus.checkedOut,
        checkInMethod: CheckInMethod.manual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(attendance.workDuration, const Duration(hours: 8, minutes: 30));
    });

    test('isCheckedIn should return true when only checked in', () {
      final attendance = AttendanceModel(
        id: 'att-123',
        employeeId: 'emp-456',
        companyId: 'comp-789',
        date: DateTime(2024, 1, 1),
        checkInTime: DateTime(2024, 1, 1, 9, 0),
        status: AttendanceStatus.checkedIn,
        checkInMethod: CheckInMethod.manual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(attendance.isCheckedIn, true);
    });

    test('workDuration should be null when not checked out', () {
      final attendance = AttendanceModel(
        id: 'att-123',
        employeeId: 'emp-456',
        companyId: 'comp-789',
        date: DateTime(2024, 1, 1),
        checkInTime: DateTime(2024, 1, 1, 9, 0),
        status: AttendanceStatus.checkedIn,
        checkInMethod: CheckInMethod.manual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(attendance.workDuration, null);
    });

    test('should convert AttendanceModel to Firestore format', () {
      final attendance = AttendanceModel(
        id: 'att-123',
        employeeId: 'emp-456',
        companyId: 'comp-789',
        date: DateTime(2024, 1, 1),
        checkInTime: DateTime(2024, 1, 1, 9, 0),
        status: AttendanceStatus.checkedIn,
        checkInMethod: CheckInMethod.automatic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final firestore = attendance.toFirestore();

      expect(firestore['employeeId'], 'emp-456');
      expect(firestore['companyId'], 'comp-789');
      expect(firestore['status'], 'checkedIn');
      expect(firestore['checkInMethod'], 'automatic');
    });
  });
}
