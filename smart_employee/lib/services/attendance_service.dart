// attendance_service.dart
// Attendance Service
//
// This service manages employee attendance records including:
// - Check-in/check-out operations
// - Automatic attendance via geofence
// - Manual attendance override
// - Proof image uploads
// - Attendance history and reports

import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/attendance_model.dart';

/// Attendance service for managing employee attendance
class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  late final Box _attendanceBox;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _attendanceBox = Hive.box('attendance');
    _isInitialized = true;
  }

  /// Check in an employee
  Future<AttendanceModel> checkIn({
    required String employeeId,
    required String companyId,
    required double latitude,
    required double longitude,
    String? geofenceId,
    bool isInsideGeofence = false,
    CheckInMethod method = CheckInMethod.manual,
    File? proofImage,
  }) async {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);

    // Check if already checked in today
    final existing = await getTodayAttendance(employeeId);
    if (existing != null && existing.isCheckedIn) {
      throw Exception('Already checked in today');
    }

    String? proofUrl;
    if (proofImage != null) {
      proofUrl = await _uploadProofImage(
        employeeId: employeeId,
        file: proofImage,
        type: 'check_in',
      );
    }

    final attendance = AttendanceModel(
      id: _uuid.v4(),
      employeeId: employeeId,
      companyId: companyId,
      date: dateOnly,
      checkInTime: now,
      status: AttendanceStatus.checkedIn,
      checkInMethod: method,
      checkInLatitude: latitude,
      checkInLongitude: longitude,
      geofenceId: geofenceId,
      isInsideGeofence: isInsideGeofence,
      isGeofenceVerified: isInsideGeofence,
      checkInProofUrl: proofUrl,
      createdAt: now,
      updatedAt: now,
    );

    // Save to Firestore
    await _firestore
        .collection('attendance')
        .doc(attendance.id)
        .set(attendance.toFirestore());

    // Save to local storage
    await _saveToLocal(attendance);

    return attendance;
  }

  /// Check out an employee
  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    bool isInsideGeofence = false,
    File? proofImage,
  }) async {
    final now = DateTime.now();

    // Get existing attendance
    final doc =
        await _firestore.collection('attendance').doc(attendanceId).get();

    if (!doc.exists) {
      throw Exception('Attendance record not found');
    }

    final existing = AttendanceModel.fromFirestore(doc);

    if (existing.checkOutTime != null) {
      throw Exception('Already checked out');
    }

    String? proofUrl;
    if (proofImage != null) {
      proofUrl = await _uploadProofImage(
        employeeId: existing.employeeId,
        file: proofImage,
        type: 'check_out',
      );
    }

    final updated = existing.copyWith(
      checkOutTime: now,
      checkOutLatitude: latitude,
      checkOutLongitude: longitude,
      checkOutProofUrl: proofUrl,
      status: AttendanceStatus.checkedOut,
      updatedAt: now,
    );

    // Update Firestore
    await _firestore
        .collection('attendance')
        .doc(attendanceId)
        .update(updated.toFirestore());

    // Update local storage
    await _saveToLocal(updated);

    return updated;
  }

  /// Automatic check-in via geofence entry
  Future<AttendanceModel?> autoCheckIn({
    required String employeeId,
    required String companyId,
    required double latitude,
    required double longitude,
    required String geofenceId,
  }) async {
    // Check if already checked in today
    final existing = await getTodayAttendance(employeeId);
    if (existing != null) {
      return null; // Already has an attendance record
    }

    return await checkIn(
      employeeId: employeeId,
      companyId: companyId,
      latitude: latitude,
      longitude: longitude,
      geofenceId: geofenceId,
      isInsideGeofence: true,
      method: CheckInMethod.automatic,
    );
  }

  /// Automatic check-out via geofence exit
  Future<AttendanceModel?> autoCheckOut({
    required String employeeId,
    required double latitude,
    required double longitude,
  }) async {
    final existing = await getTodayAttendance(employeeId);
    if (existing == null || !existing.isCheckedIn) {
      return null; // Not checked in
    }

    return await checkOut(
      attendanceId: existing.id,
      latitude: latitude,
      longitude: longitude,
      isInsideGeofence: false,
    );
  }

  /// Override attendance (admin only)
  Future<AttendanceModel> overrideAttendance({
    required String attendanceId,
    required String adminId,
    required String reason,
    AttendanceStatus? newStatus,
    DateTime? newCheckInTime,
    DateTime? newCheckOutTime,
  }) async {
    final doc =
        await _firestore.collection('attendance').doc(attendanceId).get();

    if (!doc.exists) {
      throw Exception('Attendance record not found');
    }

    final existing = AttendanceModel.fromFirestore(doc);
    final now = DateTime.now();

    final updated = existing.copyWith(
      status: newStatus ?? existing.status,
      checkInTime: newCheckInTime ?? existing.checkInTime,
      checkOutTime: newCheckOutTime ?? existing.checkOutTime,
      isManuallyOverridden: true,
      overriddenBy: adminId,
      overrideReason: reason,
      updatedAt: now,
    );

    await _firestore
        .collection('attendance')
        .doc(attendanceId)
        .update(updated.toFirestore());

    await _saveToLocal(updated);

    return updated;
  }

  /// Get today's attendance for an employee
  Future<AttendanceModel?> getTodayAttendance(String employeeId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startTimestamp = Timestamp.fromDate(startOfDay);
    final endTimestamp = Timestamp.fromDate(endOfDay);

    // Query by employeeId only (no date range to avoid composite index)
    final snapshot = await _firestore
        .collection('attendance')
        .where('employeeId', isEqualTo: employeeId)
        .limit(10) // Fetch recent records
        .get();

    // Filter by date client-side
    for (final doc in snapshot.docs) {
      final date = (doc.data()['date'] as Timestamp?);
      if (date != null &&
          date.compareTo(startTimestamp) >= 0 &&
          date.compareTo(endTimestamp) < 0) {
        return AttendanceModel.fromFirestore(doc);
      }
    }
    return null;
  }

  /// Get attendance history for an employee
  Future<List<AttendanceModel>> getAttendanceHistory({
    required String employeeId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    Query query = _firestore
        .collection('attendance')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => AttendanceModel.fromFirestore(doc))
        .toList();
  }

  /// Get attendance for all employees on a specific date (Admin)
  Future<List<AttendanceModel>> getAttendanceByDate({
    required String companyId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startTimestamp = Timestamp.fromDate(startOfDay);
    final endTimestamp = Timestamp.fromDate(endOfDay);

    // Query by companyId only (no date range to avoid composite index)
    final snapshot = await _firestore
        .collection('attendance')
        .where('companyId', isEqualTo: companyId)
        .get();

    // Filter by date client-side
    final results = <AttendanceModel>[];
    for (final doc in snapshot.docs) {
      final docDate = (doc.data()['date'] as Timestamp?);
      if (docDate != null &&
          docDate.compareTo(startTimestamp) >= 0 &&
          docDate.compareTo(endTimestamp) < 0) {
        results.add(AttendanceModel.fromFirestore(doc));
      }
    }
    return results;
  }

  /// Stream real-time attendance updates
  Stream<List<AttendanceModel>> streamTodayAttendance(String companyId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startTimestamp = Timestamp.fromDate(startOfDay);
    final endTimestamp = Timestamp.fromDate(endOfDay);

    // Query by companyId only (no date range to avoid composite index)
    return _firestore
        .collection('attendance')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final docDate = (doc.data()['date'] as Timestamp?);
            return docDate != null &&
                docDate.compareTo(startTimestamp) >= 0 &&
                docDate.compareTo(endTimestamp) < 0;
          })
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Upload proof image to Firebase Storage
  Future<String> _uploadProofImage({
    required String employeeId,
    required File file,
    required String type,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'attendance_proofs/$employeeId/${type}_$timestamp.jpg';

    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Save attendance to local storage
  Future<void> _saveToLocal(AttendanceModel attendance) async {
    if (!_isInitialized) await initialize();
    await _attendanceBox.put(attendance.id, attendance.toJson());
  }

  /// Get attendance stats for a date range
  Future<AttendanceStats> getAttendanceStats({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final records = await getAttendanceHistory(
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
      limit: 365,
    );

    int present = 0;
    int absent = 0;
    int late = 0;
    int halfDay = 0;
    Duration totalWorkTime = Duration.zero;

    for (final record in records) {
      switch (record.status) {
        case AttendanceStatus.checkedIn:
        case AttendanceStatus.checkedOut:
          present++;
          if (record.workDuration != null) {
            totalWorkTime += record.workDuration!;
          }
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.halfDay:
          halfDay++;
          break;
        default:
          break;
      }

      // Check for late (assuming 9:00 AM start time)
      if (record.checkInTime != null) {
        final checkInHour = record.checkInTime!.hour;
        if (checkInHour >= 9 && record.checkInTime!.minute > 15) {
          late++;
        }
      }
    }

    return AttendanceStats(
      totalDays: records.length,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      halfDays: halfDay,
      totalWorkTime: totalWorkTime,
    );
  }
}

/// Attendance statistics
class AttendanceStats {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int halfDays;
  final Duration totalWorkTime;

  AttendanceStats({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.halfDays,
    required this.totalWorkTime,
  });

  double get attendancePercentage =>
      totalDays > 0 ? (presentDays / totalDays) * 100 : 0;

  String get averageWorkTimePerDay {
    if (presentDays == 0) return '0h 0m';
    final avgMinutes = totalWorkTime.inMinutes ~/ presentDays;
    final hours = avgMinutes ~/ 60;
    final minutes = avgMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
