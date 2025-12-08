// location_model.dart
// Location data model
// 
// This model represents a location record captured from the device.
// It includes coordinates, accuracy, timestamp, and speed data
// for employee tracking purposes.

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Location model representing a GPS location record
class LocationModel extends Equatable {
  final String id;
  final String employeeId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final String? activity; // walking, driving, still, etc.
  final bool isMocked;
  final bool isSynced;

  const LocationModel({
    required this.id,
    required this.employeeId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
    this.activity,
    this.isMocked = false,
    this.isSynced = false,
  });

  /// Create LocationModel from Firestore document
  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      accuracy: (data['accuracy'] ?? 0).toDouble(),
      altitude: data['altitude']?.toDouble(),
      speed: data['speed']?.toDouble(),
      heading: data['heading']?.toDouble(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activity: data['activity'],
      isMocked: data['isMocked'] ?? false,
      isSynced: true, // If from Firestore, it's synced
    );
  }

  /// Create LocationModel from JSON map
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      altitude: json['altitude']?.toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      activity: json['activity'],
      isMocked: json['isMocked'] ?? false,
      isSynced: json['isSynced'] ?? false,
    );
  }

  /// Create LocationModel from native channel data
  factory LocationModel.fromNativeData(
    Map<dynamic, dynamic> data,
    String employeeId,
  ) {
    return LocationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      employeeId: employeeId,
      latitude: (data['lat'] ?? data['latitude'] ?? 0).toDouble(),
      longitude: (data['lng'] ?? data['longitude'] ?? 0).toDouble(),
      accuracy: (data['accuracy'] ?? 0).toDouble(),
      altitude: data['altitude']?.toDouble(),
      speed: data['speed']?.toDouble(),
      heading: data['heading']?.toDouble(),
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int)
          : DateTime.now(),
      activity: data['activity'],
      isMocked: data['isMocked'] ?? false,
      isSynced: false,
    );
  }

  /// Convert to Firestore document map
  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': Timestamp.fromDate(timestamp),
      'activity': activity,
      'isMocked': isMocked,
    };
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
      'activity': activity,
      'isMocked': isMocked,
      'isSynced': isSynced,
    };
  }

  /// Create a copy with modified fields
  LocationModel copyWith({
    String? id,
    String? employeeId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    String? activity,
    bool? isMocked,
    bool? isSynced,
  }) {
    return LocationModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      activity: activity ?? this.activity,
      isMocked: isMocked ?? this.isMocked,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        latitude,
        longitude,
        accuracy,
        altitude,
        speed,
        heading,
        timestamp,
        activity,
        isMocked,
        isSynced,
      ];
}
