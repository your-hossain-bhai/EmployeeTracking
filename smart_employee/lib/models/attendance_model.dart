// attendance_model.dart
// Attendance record data model
//
// This model represents an attendance record for an employee,
// including check-in/check-out times, location data, proof images,
// and geofence verification status.

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Attendance status types
enum AttendanceStatus {
  checkedIn,
  checkedOut,
  onBreak,
  absent,
  halfDay,
  workFromHome,
}

/// Check-in method types
enum CheckInMethod {
  automatic, // Via geofence
  manual, // Manual check-in
  qrCode, // QR code scan
  biometric, // Fingerprint/face
}

/// Attendance model representing a daily attendance record
class AttendanceModel extends Equatable {
  final String id;
  final String employeeId;
  final String companyId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final CheckInMethod checkInMethod;

  // Location data at check-in/out
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;

  // Geofence verification
  final String? geofenceId;
  final bool isInsideGeofence;
  final bool isGeofenceVerified;

  // Proof uploads
  final String? checkInProofUrl;
  final String? checkOutProofUrl;

  // Notes and metadata
  final String? notes;
  final bool isManuallyOverridden;
  final String? overriddenBy;
  final String? overrideReason;

  // Sync status
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.companyId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    required this.checkInMethod,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.geofenceId,
    this.isInsideGeofence = false,
    this.isGeofenceVerified = false,
    this.checkInProofUrl,
    this.checkOutProofUrl,
    this.notes,
    this.isManuallyOverridden = false,
    this.overriddenBy,
    this.overrideReason,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate total work duration
  Duration? get workDuration {
    if (checkInTime == null || checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime!);
  }

  /// Check if currently checked in
  bool get isCheckedIn =>
      checkInTime != null &&
      checkOutTime == null &&
      status == AttendanceStatus.checkedIn;

  /// Check if check-in was late (after 9:15 AM)
  bool get isLate {
    if (checkInTime == null) return false;
    final lateThreshold = DateTime(
      checkInTime!.year,
      checkInTime!.month,
      checkInTime!.day,
      9,
      15,
    );
    return checkInTime!.isAfter(lateThreshold);
  }

  /// Create AttendanceModel from Firestore document
  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      companyId: data['companyId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkInTime: (data['checkInTime'] as Timestamp?)?.toDate(),
      checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      checkInMethod: CheckInMethod.values.firstWhere(
        (e) => e.name == data['checkInMethod'],
        orElse: () => CheckInMethod.manual,
      ),
      checkInLatitude: data['checkInLatitude']?.toDouble(),
      checkInLongitude: data['checkInLongitude']?.toDouble(),
      checkOutLatitude: data['checkOutLatitude']?.toDouble(),
      checkOutLongitude: data['checkOutLongitude']?.toDouble(),
      geofenceId: data['geofenceId'],
      isInsideGeofence: data['isInsideGeofence'] ?? false,
      isGeofenceVerified: data['isGeofenceVerified'] ?? false,
      checkInProofUrl: data['checkInProofUrl'],
      checkOutProofUrl: data['checkOutProofUrl'],
      notes: data['notes'],
      isManuallyOverridden: data['isManuallyOverridden'] ?? false,
      overriddenBy: data['overriddenBy'],
      overrideReason: data['overrideReason'],
      isSynced: true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create AttendanceModel from JSON map
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      companyId: json['companyId'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      checkInMethod: CheckInMethod.values.firstWhere(
        (e) => e.name == json['checkInMethod'],
        orElse: () => CheckInMethod.manual,
      ),
      checkInLatitude: json['checkInLatitude']?.toDouble(),
      checkInLongitude: json['checkInLongitude']?.toDouble(),
      checkOutLatitude: json['checkOutLatitude']?.toDouble(),
      checkOutLongitude: json['checkOutLongitude']?.toDouble(),
      geofenceId: json['geofenceId'],
      isInsideGeofence: json['isInsideGeofence'] ?? false,
      isGeofenceVerified: json['isGeofenceVerified'] ?? false,
      checkInProofUrl: json['checkInProofUrl'],
      checkOutProofUrl: json['checkOutProofUrl'],
      notes: json['notes'],
      isManuallyOverridden: json['isManuallyOverridden'] ?? false,
      overriddenBy: json['overriddenBy'],
      overrideReason: json['overrideReason'],
      isSynced: json['isSynced'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Convert to Firestore document map
  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'companyId': companyId,
      'date': Timestamp.fromDate(date),
      'checkInTime':
          checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkOutTime':
          checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'status': status.name,
      'checkInMethod': checkInMethod.name,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'geofenceId': geofenceId,
      'isInsideGeofence': isInsideGeofence,
      'isGeofenceVerified': isGeofenceVerified,
      'checkInProofUrl': checkInProofUrl,
      'checkOutProofUrl': checkOutProofUrl,
      'notes': notes,
      'isManuallyOverridden': isManuallyOverridden,
      'overriddenBy': overriddenBy,
      'overrideReason': overrideReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'companyId': companyId,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'status': status.name,
      'checkInMethod': checkInMethod.name,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'geofenceId': geofenceId,
      'isInsideGeofence': isInsideGeofence,
      'isGeofenceVerified': isGeofenceVerified,
      'checkInProofUrl': checkInProofUrl,
      'checkOutProofUrl': checkOutProofUrl,
      'notes': notes,
      'isManuallyOverridden': isManuallyOverridden,
      'overriddenBy': overriddenBy,
      'overrideReason': overrideReason,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  AttendanceModel copyWith({
    String? id,
    String? employeeId,
    String? companyId,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    AttendanceStatus? status,
    CheckInMethod? checkInMethod,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    String? geofenceId,
    bool? isInsideGeofence,
    bool? isGeofenceVerified,
    String? checkInProofUrl,
    String? checkOutProofUrl,
    String? notes,
    bool? isManuallyOverridden,
    String? overriddenBy,
    String? overrideReason,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      companyId: companyId ?? this.companyId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      checkInMethod: checkInMethod ?? this.checkInMethod,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      geofenceId: geofenceId ?? this.geofenceId,
      isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
      isGeofenceVerified: isGeofenceVerified ?? this.isGeofenceVerified,
      checkInProofUrl: checkInProofUrl ?? this.checkInProofUrl,
      checkOutProofUrl: checkOutProofUrl ?? this.checkOutProofUrl,
      notes: notes ?? this.notes,
      isManuallyOverridden: isManuallyOverridden ?? this.isManuallyOverridden,
      overriddenBy: overriddenBy ?? this.overriddenBy,
      overrideReason: overrideReason ?? this.overrideReason,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        companyId,
        date,
        checkInTime,
        checkOutTime,
        status,
        checkInMethod,
        checkInLatitude,
        checkInLongitude,
        checkOutLatitude,
        checkOutLongitude,
        geofenceId,
        isInsideGeofence,
        isGeofenceVerified,
        checkInProofUrl,
        checkOutProofUrl,
        notes,
        isManuallyOverridden,
        overriddenBy,
        overrideReason,
        isSynced,
        createdAt,
        updatedAt,
      ];
}
