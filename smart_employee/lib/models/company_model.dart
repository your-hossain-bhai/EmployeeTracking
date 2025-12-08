// company_model.dart
// Company data model
// 
// This model represents a company/organization in the system.
// It includes company details, settings, and configuration.

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Company model representing an organization
class CompanyModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  
  // Settings
  final int locationUpdateIntervalSeconds;
  final int geofenceRadiusMeters;
  final bool requireProofForCheckIn;
  final bool allowManualCheckIn;
  final int maxCheckInDistanceMeters;
  
  // Work hours defaults
  final String defaultWorkStartTime;
  final String defaultWorkEndTime;
  final List<int> defaultWorkDays;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const CompanyModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.locationUpdateIntervalSeconds = 30,
    this.geofenceRadiusMeters = 100,
    this.requireProofForCheckIn = false,
    this.allowManualCheckIn = true,
    this.maxCheckInDistanceMeters = 500,
    this.defaultWorkStartTime = '09:00',
    this.defaultWorkEndTime = '18:00',
    this.defaultWorkDays = const [1, 2, 3, 4, 5],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Create CompanyModel from Firestore document
  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompanyModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      logoUrl: data['logoUrl'],
      address: data['address'],
      phone: data['phone'],
      email: data['email'],
      website: data['website'],
      locationUpdateIntervalSeconds:
          data['locationUpdateIntervalSeconds'] ?? 30,
      geofenceRadiusMeters: data['geofenceRadiusMeters'] ?? 100,
      requireProofForCheckIn: data['requireProofForCheckIn'] ?? false,
      allowManualCheckIn: data['allowManualCheckIn'] ?? true,
      maxCheckInDistanceMeters: data['maxCheckInDistanceMeters'] ?? 500,
      defaultWorkStartTime: data['defaultWorkStartTime'] ?? '09:00',
      defaultWorkEndTime: data['defaultWorkEndTime'] ?? '18:00',
      defaultWorkDays: data['defaultWorkDays'] != null
          ? List<int>.from(data['defaultWorkDays'])
          : const [1, 2, 3, 4, 5],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Create CompanyModel from JSON map
  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logoUrl: json['logoUrl'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      locationUpdateIntervalSeconds:
          json['locationUpdateIntervalSeconds'] ?? 30,
      geofenceRadiusMeters: json['geofenceRadiusMeters'] ?? 100,
      requireProofForCheckIn: json['requireProofForCheckIn'] ?? false,
      allowManualCheckIn: json['allowManualCheckIn'] ?? true,
      maxCheckInDistanceMeters: json['maxCheckInDistanceMeters'] ?? 500,
      defaultWorkStartTime: json['defaultWorkStartTime'] ?? '09:00',
      defaultWorkEndTime: json['defaultWorkEndTime'] ?? '18:00',
      defaultWorkDays: json['defaultWorkDays'] != null
          ? List<int>.from(json['defaultWorkDays'])
          : const [1, 2, 3, 4, 5],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  /// Convert to Firestore document map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'locationUpdateIntervalSeconds': locationUpdateIntervalSeconds,
      'geofenceRadiusMeters': geofenceRadiusMeters,
      'requireProofForCheckIn': requireProofForCheckIn,
      'allowManualCheckIn': allowManualCheckIn,
      'maxCheckInDistanceMeters': maxCheckInDistanceMeters,
      'defaultWorkStartTime': defaultWorkStartTime,
      'defaultWorkEndTime': defaultWorkEndTime,
      'defaultWorkDays': defaultWorkDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'locationUpdateIntervalSeconds': locationUpdateIntervalSeconds,
      'geofenceRadiusMeters': geofenceRadiusMeters,
      'requireProofForCheckIn': requireProofForCheckIn,
      'allowManualCheckIn': allowManualCheckIn,
      'maxCheckInDistanceMeters': maxCheckInDistanceMeters,
      'defaultWorkStartTime': defaultWorkStartTime,
      'defaultWorkEndTime': defaultWorkEndTime,
      'defaultWorkDays': defaultWorkDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create a copy with modified fields
  CompanyModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? address,
    String? phone,
    String? email,
    String? website,
    int? locationUpdateIntervalSeconds,
    int? geofenceRadiusMeters,
    bool? requireProofForCheckIn,
    bool? allowManualCheckIn,
    int? maxCheckInDistanceMeters,
    String? defaultWorkStartTime,
    String? defaultWorkEndTime,
    List<int>? defaultWorkDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      locationUpdateIntervalSeconds:
          locationUpdateIntervalSeconds ?? this.locationUpdateIntervalSeconds,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      requireProofForCheckIn:
          requireProofForCheckIn ?? this.requireProofForCheckIn,
      allowManualCheckIn: allowManualCheckIn ?? this.allowManualCheckIn,
      maxCheckInDistanceMeters:
          maxCheckInDistanceMeters ?? this.maxCheckInDistanceMeters,
      defaultWorkStartTime: defaultWorkStartTime ?? this.defaultWorkStartTime,
      defaultWorkEndTime: defaultWorkEndTime ?? this.defaultWorkEndTime,
      defaultWorkDays: defaultWorkDays ?? this.defaultWorkDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        logoUrl,
        address,
        phone,
        email,
        website,
        locationUpdateIntervalSeconds,
        geofenceRadiusMeters,
        requireProofForCheckIn,
        allowManualCheckIn,
        maxCheckInDistanceMeters,
        defaultWorkStartTime,
        defaultWorkEndTime,
        defaultWorkDays,
        createdAt,
        updatedAt,
        isActive,
      ];
}
