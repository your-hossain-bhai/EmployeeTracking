// test/unit/location_model_test.dart
// Unit Tests for Location Model
//
// These tests verify the Location model's serialization, deserialization,
// and conversion methods.

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_employee/models/location_model.dart';

void main() {
  group('LocationModel', () {
    test('should create a LocationModel from JSON', () {
      final json = {
        'id': 'loc-123',
        'employeeId': 'emp-456',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'accuracy': 10.5,
        'speed': 5.0,
        'timestamp': '2024-01-01T12:00:00.000Z',
        'isMocked': false,
        'isSynced': true,
      };

      final location = LocationModel.fromJson(json);

      expect(location.id, 'loc-123');
      expect(location.employeeId, 'emp-456');
      expect(location.latitude, 37.7749);
      expect(location.longitude, -122.4194);
      expect(location.accuracy, 10.5);
      expect(location.isMocked, false);
      expect(location.isSynced, true);
    });

    test('should convert LocationModel to JSON', () {
      final location = LocationModel(
        id: 'loc-123',
        employeeId: 'emp-456',
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.5,
        speed: 5.0,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final json = location.toJson();

      expect(json['id'], 'loc-123');
      expect(json['employeeId'], 'emp-456');
      expect(json['latitude'], 37.7749);
      expect(json['longitude'], -122.4194);
      expect(json['accuracy'], 10.5);
    });

    test('should create LocationModel from native data', () {
      final nativeData = {
        'lat': 37.7749,
        'lng': -122.4194,
        'accuracy': 10.0,
        'speed': 3.5,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isMocked': false,
      };

      final location = LocationModel.fromNativeData(nativeData, 'emp-123');

      expect(location.employeeId, 'emp-123');
      expect(location.latitude, 37.7749);
      expect(location.longitude, -122.4194);
      expect(location.accuracy, 10.0);
    });

    test('copyWith should create a new instance with updated fields', () {
      final original = LocationModel(
        id: 'loc-123',
        employeeId: 'emp-456',
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.5,
        timestamp: DateTime.now(),
        isSynced: false,
      );

      final updated = original.copyWith(isSynced: true);

      expect(updated.id, original.id);
      expect(updated.latitude, original.latitude);
      expect(updated.isSynced, true);
    });
  });
}
