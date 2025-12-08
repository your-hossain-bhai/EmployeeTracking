// geofence_model.dart
// Geofence data model
// 
// This model represents a geofence zone used for automatic
// attendance tracking and location-based verification.
// Geofences define circular areas around office locations.

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Geofence type categorization
enum GeofenceType {
  office,
  branch,
  warehouse,
  clientSite,
  custom,
}

/// Geofence model representing a geographic boundary
class GeofenceModel extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final GeofenceType type;
  final bool isActive;
  final String? address;
  
  // Work hours for this location
  final String? workStartTime; // HH:mm format
  final String? workEndTime; // HH:mm format
  final List<int>? workDays; // 1=Monday, 7=Sunday
  
  // Notification settings
  final bool notifyOnEntry;
  final bool notifyOnExit;
  final bool autoCheckIn;
  final bool autoCheckOut;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final bool isSynced;

  const GeofenceModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.type,
    this.isActive = true,
    this.address,
    this.workStartTime,
    this.workEndTime,
    this.workDays,
    this.notifyOnEntry = true,
    this.notifyOnExit = true,
    this.autoCheckIn = true,
    this.autoCheckOut = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.isSynced = false,
  });

  /// Create GeofenceModel from Firestore document
  factory GeofenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GeofenceModel(
      id: doc.id,
      companyId: data['companyId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      radius: (data['radius'] ?? 100).toDouble(),
      type: GeofenceType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => GeofenceType.office,
      ),
      isActive: data['isActive'] ?? true,
      address: data['address'],
      workStartTime: data['workStartTime'],
      workEndTime: data['workEndTime'],
      workDays: data['workDays'] != null
          ? List<int>.from(data['workDays'])
          : null,
      notifyOnEntry: data['notifyOnEntry'] ?? true,
      notifyOnExit: data['notifyOnExit'] ?? true,
      autoCheckIn: data['autoCheckIn'] ?? true,
      autoCheckOut: data['autoCheckOut'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      isSynced: true,
    );
  }

  /// Create GeofenceModel from JSON map
  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    return GeofenceModel(
      id: json['id'] ?? '',
      companyId: json['companyId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      radius: (json['radius'] ?? 100).toDouble(),
      type: GeofenceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GeofenceType.office,
      ),
      isActive: json['isActive'] ?? true,
      address: json['address'],
      workStartTime: json['workStartTime'],
      workEndTime: json['workEndTime'],
      workDays: json['workDays'] != null
          ? List<int>.from(json['workDays'])
          : null,
      notifyOnEntry: json['notifyOnEntry'] ?? true,
      notifyOnExit: json['notifyOnExit'] ?? true,
      autoCheckIn: json['autoCheckIn'] ?? true,
      autoCheckOut: json['autoCheckOut'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      createdBy: json['createdBy'],
      isSynced: json['isSynced'] ?? false,
    );
  }

  /// Convert to Firestore document map
  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'type': type.name,
      'isActive': isActive,
      'address': address,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
      'workDays': workDays,
      'notifyOnEntry': notifyOnEntry,
      'notifyOnExit': notifyOnExit,
      'autoCheckIn': autoCheckIn,
      'autoCheckOut': autoCheckOut,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'type': type.name,
      'isActive': isActive,
      'address': address,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
      'workDays': workDays,
      'notifyOnEntry': notifyOnEntry,
      'notifyOnExit': notifyOnExit,
      'autoCheckIn': autoCheckIn,
      'autoCheckOut': autoCheckOut,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'isSynced': isSynced,
    };
  }

  /// Convert to native channel format for Android geofencing
  Map<String, dynamic> toNativeFormat() {
    return {
      'id': id,
      'lat': latitude,
      'lng': longitude,
      'radius': radius,
    };
  }

  /// Create a copy with modified fields
  GeofenceModel copyWith({
    String? id,
    String? companyId,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    double? radius,
    GeofenceType? type,
    bool? isActive,
    String? address,
    String? workStartTime,
    String? workEndTime,
    List<int>? workDays,
    bool? notifyOnEntry,
    bool? notifyOnExit,
    bool? autoCheckIn,
    bool? autoCheckOut,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isSynced,
  }) {
    return GeofenceModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      workDays: workDays ?? this.workDays,
      notifyOnEntry: notifyOnEntry ?? this.notifyOnEntry,
      notifyOnExit: notifyOnExit ?? this.notifyOnExit,
      autoCheckIn: autoCheckIn ?? this.autoCheckIn,
      autoCheckOut: autoCheckOut ?? this.autoCheckOut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        name,
        description,
        latitude,
        longitude,
        radius,
        type,
        isActive,
        address,
        workStartTime,
        workEndTime,
        workDays,
        notifyOnEntry,
        notifyOnExit,
        autoCheckIn,
        autoCheckOut,
        createdAt,
        updatedAt,
        createdBy,
        isSynced,
      ];
}
