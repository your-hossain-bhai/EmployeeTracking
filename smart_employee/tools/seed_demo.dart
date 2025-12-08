// tools/seed_demo.dart
// Demo Data Seeder for Smart Employee
//
// This script populates Firestore with sample data for testing and demonstration.
// It creates a sample company, admin user, employees, geofences, and location logs.
//
// Usage:
//   1. Configure Firebase in your project
//   2. Run: dart run tools/seed_demo.dart
//
// NOTE: This script requires firebase_admin package or Firebase CLI.
// For Flutter projects, you can run this from a separate Dart script
// or use the Firebase Console to import data.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

// UUID v4 generator
class UuidGenerator {
  static final Random _random = Random.secure();

  static String generate() {
    // Generate UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set version (4) and variant (8, 9, A, or B)
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

/// Demo data seeder
/// 
/// This generates JSON files that can be imported into Firestore
/// via the Firebase Console or Firebase CLI.
void main() async {
  print('🌱 Smart Employee Demo Data Seeder');
  print('==================================\n');

  final seeder = DemoDataSeeder();
  await seeder.generateAllData();

  print('\n✅ Demo data generated successfully!');
  print('\nTo import data into Firestore:');
  print('1. Go to Firebase Console > Firestore Database');
  print('2. Click "Import/Export" or use the collection menu');
  print('3. Import the generated JSON files from the "seed_data" folder');
  print('\nAlternatively, use the Firebase CLI:');
  print('  firebase firestore:delete --all-collections');
  print('  firebase emulators:start --import=./seed_data');
}

class DemoDataSeeder {
  final String outputDir = 'seed_data';
  final Random _random = Random();

  Future<void> generateAllData() async {
    // Create output directory
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Generate data
    final companyId = _generateId();
    final adminId = _generateId();
    final employeeIds = List.generate(3, (_) => _generateId());
    final geofenceId = _generateId();

    // Generate company
    print('📦 Generating company...');
    await _generateCompany(companyId);

    // Generate admin user
    print('👤 Generating admin user...');
    await _generateAdmin(adminId, companyId);

    // Generate employees
    print('👥 Generating employees...');
    await _generateEmployees(employeeIds, companyId);

    // Generate geofence
    print('📍 Generating geofence...');
    await _generateGeofence(geofenceId, companyId, adminId);

    // Generate attendance records
    print('📋 Generating attendance records...');
    await _generateAttendance(employeeIds, companyId, geofenceId);

    // Generate location logs
    print('🗺️ Generating location logs...');
    await _generateLocations(employeeIds);

    // Generate summary file
    print('📄 Generating summary...');
    await _generateSummary(companyId, adminId, employeeIds, geofenceId);
  }

  Future<void> _generateCompany(String companyId) async {
    final company = {
      companyId: {
        'name': 'Demo Corp',
        'description': 'A demo company for Smart Employee app testing',
        'email': 'contact@democorp.com',
        'phone': '+1-555-0100',
        'address': '123 Tech Street, San Francisco, CA 94102',
        'locationUpdateIntervalSeconds': 30,
        'geofenceRadiusMeters': 100,
        'requireProofForCheckIn': false,
        'allowManualCheckIn': true,
        'maxCheckInDistanceMeters': 500,
        'defaultWorkStartTime': '09:00',
        'defaultWorkEndTime': '18:00',
        'defaultWorkDays': [1, 2, 3, 4, 5],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': true,
      }
    };

    await _writeJson('companies.json', company);
  }

  Future<void> _generateAdmin(String adminId, String companyId) async {
    final admin = {
      adminId: {
        'email': 'admin@democorp.com',
        'displayName': 'Admin User',
        'role': 'admin',
        'companyId': companyId,
        'phoneNumber': '+1-555-0101',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }
    };

    await _writeJson('users_admin.json', admin);
    print('   Admin email: admin@democorp.com');
    print('   Admin password: Demo123! (set this in Firebase Auth)');
  }

  Future<void> _generateEmployees(
      List<String> employeeIds, String companyId) async {
    final employees = <String, dynamic>{};
    final employeeData = [
      {'name': 'John Smith', 'email': 'john@democorp.com'},
      {'name': 'Sarah Johnson', 'email': 'sarah@democorp.com'},
      {'name': 'Michael Chen', 'email': 'michael@democorp.com'},
    ];

    for (var i = 0; i < employeeIds.length; i++) {
      employees[employeeIds[i]] = {
        'email': employeeData[i]['email'],
        'displayName': employeeData[i]['name'],
        'role': 'employee',
        'companyId': companyId,
        'phoneNumber': '+1-555-010${i + 2}',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      print('   Employee: ${employeeData[i]['name']} (${employeeData[i]['email']})');
    }

    await _writeJson('users_employees.json', employees);
    print('   Employee password: Demo123! (set this in Firebase Auth)');
  }

  Future<void> _generateGeofence(
      String geofenceId, String companyId, String createdBy) async {
    final geofence = {
      geofenceId: {
        'companyId': companyId,
        'name': 'Demo Corp HQ',
        'description': 'Main office location',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'radius': 100.0,
        'type': 'office',
        'isActive': true,
        'address': '123 Tech Street, San Francisco, CA 94102',
        'workStartTime': '09:00',
        'workEndTime': '18:00',
        'workDays': [1, 2, 3, 4, 5],
        'notifyOnEntry': true,
        'notifyOnExit': true,
        'autoCheckIn': true,
        'autoCheckOut': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'createdBy': createdBy,
      }
    };

    await _writeJson('geofences.json', geofence);
    print('   Geofence: Demo Corp HQ (San Francisco)');
  }

  Future<void> _generateAttendance(
      List<String> employeeIds, String companyId, String geofenceId) async {
    final attendance = <String, dynamic>{};
    final today = DateTime.now();

    for (final employeeId in employeeIds) {
      // Generate attendance for last 7 days
      for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
        final date = today.subtract(Duration(days: dayOffset));
        // Skip weekends
        if (date.weekday == 6 || date.weekday == 7) continue;

        final attId = _generateId();
        final checkInTime = DateTime(date.year, date.month, date.day,
            8 + _random.nextInt(2), _random.nextInt(60));
        final checkOutTime = DateTime(date.year, date.month, date.day,
            17 + _random.nextInt(2), _random.nextInt(60));

        attendance[attId] = {
          'employeeId': employeeId,
          'companyId': companyId,
          'date': DateTime(date.year, date.month, date.day).toIso8601String(),
          'checkInTime': checkInTime.toIso8601String(),
          'checkOutTime': dayOffset == 0 ? null : checkOutTime.toIso8601String(),
          'status': dayOffset == 0 ? 'checkedIn' : 'checkedOut',
          'checkInMethod': _random.nextBool() ? 'automatic' : 'manual',
          'checkInLatitude': 37.7749 + (_random.nextDouble() - 0.5) * 0.001,
          'checkInLongitude': -122.4194 + (_random.nextDouble() - 0.5) * 0.001,
          'checkOutLatitude': dayOffset == 0
              ? null
              : 37.7749 + (_random.nextDouble() - 0.5) * 0.001,
          'checkOutLongitude': dayOffset == 0
              ? null
              : -122.4194 + (_random.nextDouble() - 0.5) * 0.001,
          'geofenceId': geofenceId,
          'isInsideGeofence': true,
          'isGeofenceVerified': true,
          'isManuallyOverridden': false,
          'createdAt': checkInTime.toIso8601String(),
          'updatedAt': (dayOffset == 0 ? checkInTime : checkOutTime)
              .toIso8601String(),
        };
      }
    }

    await _writeJson('attendance.json', attendance);
    print('   Generated ${attendance.length} attendance records');
  }

  Future<void> _generateLocations(List<String> employeeIds) async {
    final locations = <String, dynamic>{};
    final now = DateTime.now();

    for (final employeeId in employeeIds) {
      // Generate location logs for last 4 hours (every 5 minutes)
      for (var i = 0; i < 48; i++) {
        final locId = _generateId();
        final timestamp = now.subtract(Duration(minutes: i * 5));

        locations[locId] = {
          'employeeId': employeeId,
          'latitude': 37.7749 + (_random.nextDouble() - 0.5) * 0.002,
          'longitude': -122.4194 + (_random.nextDouble() - 0.5) * 0.002,
          'accuracy': 5.0 + _random.nextDouble() * 20,
          'altitude': 10.0 + _random.nextDouble() * 5,
          'speed': _random.nextDouble() * 5,
          'heading': _random.nextDouble() * 360,
          'timestamp': timestamp.toIso8601String(),
          'isMocked': false,
        };
      }
    }

    await _writeJson('locations.json', locations);
    print('   Generated ${locations.length} location logs');
  }

  Future<void> _generateSummary(String companyId, String adminId,
      List<String> employeeIds, String geofenceId) async {
    final summary = {
      'generatedAt': DateTime.now().toIso8601String(),
      'companyId': companyId,
      'adminId': adminId,
      'employeeIds': employeeIds,
      'geofenceId': geofenceId,
      'credentials': {
        'admin': {'email': 'admin@democorp.com', 'password': 'Demo123!'},
        'employees': [
          {'email': 'john@democorp.com', 'password': 'Demo123!'},
          {'email': 'sarah@democorp.com', 'password': 'Demo123!'},
          {'email': 'michael@democorp.com', 'password': 'Demo123!'},
        ]
      },
      'instructions': [
        '1. Create Firebase Auth users with the emails and passwords above',
        '2. Import the JSON files into Firestore collections',
        '3. Use the admin account to access the admin dashboard',
        '4. Use employee accounts to test the employee portal',
      ]
    };

    await _writeJson('_summary.json', summary);
  }

  Future<void> _writeJson(String filename, Map<String, dynamic> data) async {
    final file = File('$outputDir/$filename');
    final encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data));
  }

  String _generateId() {
    return UuidGenerator.generate();
  }
}
