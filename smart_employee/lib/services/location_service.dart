// location_service.dart
// Location Service
//
// This service provides location-related functionality including:
// - Real-time location streaming from employees
// - Location permission handling
// - Distance calculations for geofence checks
// - Integration with geolocator package

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'native_channel_service.dart';
import '../models/location_model.dart';
import '../models/user_model.dart';

/// Location service for managing employee location tracking
class LocationService {
  final NativeChannelService _nativeChannelService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LocationService(this._nativeChannelService);

  /// Get current location using Geolocator
  Future<Position?> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings for permissions
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Stream of employee locations for real-time tracking (Admin)
  Stream<List<EmployeeLocation>> streamAllEmployeeLocations(String companyId) {
    // Use simpler query to avoid composite index issues
    // Filter role and isActive client-side
    return _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .asyncMap((snapshot) async {
      // Filter employees client-side to avoid needing composite indexes
      final employees = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.role == 'employee' && user.isActive)
          .toList();

      print(
          'Found ${employees.length} active employees for company $companyId');

      final locations = <EmployeeLocation>[];

      for (final employee in employees) {
        try {
          // Get locations for employee - no orderBy to avoid composite index requirement
          // Sort client-side instead
          final locationSnapshot = await _firestore
              .collection('locations')
              .where('employeeId', isEqualTo: employee.id)
              .get();

          if (locationSnapshot.docs.isNotEmpty) {
            // Sort by timestamp client-side to get the latest
            final allLocations = locationSnapshot.docs
                .map((doc) => LocationModel.fromFirestore(doc))
                .toList();
            allLocations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            locations.add(
              EmployeeLocation(
                  employee: employee, location: allLocations.first),
            );
          } else {
            locations.add(
              EmployeeLocation(employee: employee, location: null),
            );
          }
        } catch (e) {
          print('Error getting location for ${employee.displayName}: $e');
          // Add employee without location if there's an error
          locations.add(
            EmployeeLocation(employee: employee, location: null),
          );
        }
      }

      return locations;
    });
  }

  /// Get real-time location updates for a specific employee
  Stream<LocationModel?> streamEmployeeLocation(String employeeId) {
    // Removed orderBy to avoid needing composite index
    // Sort client-side instead
    return _firestore
        .collection('locations')
        .where('employeeId', isEqualTo: employeeId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      // Sort client-side to get the latest
      final locations =
          snapshot.docs.map((doc) => LocationModel.fromFirestore(doc)).toList();
      locations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return locations.first;
    });
  }

  /// Calculate distance between two points in meters
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if a position is inside a geofence
  bool isInsideGeofence({
    required double latitude,
    required double longitude,
    required double geofenceLatitude,
    required double geofenceLongitude,
    required double geofenceRadius,
  }) {
    final distance = calculateDistance(
      startLatitude: latitude,
      startLongitude: longitude,
      endLatitude: geofenceLatitude,
      endLongitude: geofenceLongitude,
    );
    return distance <= geofenceRadius;
  }

  /// Save location to Firestore
  Future<void> saveLocation(LocationModel location) async {
    await _firestore
        .collection('locations')
        .doc(location.id)
        .set(location.toFirestore());
  }

  /// Get location history for an employee
  Future<List<LocationModel>> getLocationHistory({
    required String employeeId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    Query query = _firestore
        .collection('locations')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('timestamp', descending: true);

    if (startDate != null) {
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'timestamp',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => LocationModel.fromFirestore(doc))
        .toList();
  }

  /// Get native channel service stream
  Stream<Map<String, dynamic>> get nativeLocationStream =>
      _nativeChannelService.locationStream;
}

/// Model combining employee and their current location
class EmployeeLocation {
  final UserModel employee;
  final LocationModel? location;

  EmployeeLocation({required this.employee, this.location});

  bool get hasLocation => location != null;

  bool get isOnline {
    if (location == null) return false;
    // Consider online if location is within last 5 minutes
    return DateTime.now().difference(location!.timestamp).inMinutes < 5;
  }
}
