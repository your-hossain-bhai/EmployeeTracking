// attendance_controller.dart
// Attendance Controller (BLoC)
// 
// This controller manages attendance state using flutter_bloc.
// It handles check-in, check-out, and attendance history.

import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../services/attendance_service.dart';
import '../services/geofence_service.dart';
import '../models/attendance_model.dart';

// ============ Events ============

/// Base class for attendance events
abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check in
class AttendanceCheckIn extends AttendanceEvent {
  final String employeeId;
  final String companyId;
  final double latitude;
  final double longitude;
  final String? geofenceId;
  final bool isInsideGeofence;
  final CheckInMethod method;
  final File? proofImage;

  const AttendanceCheckIn({
    required this.employeeId,
    required this.companyId,
    required this.latitude,
    required this.longitude,
    this.geofenceId,
    this.isInsideGeofence = false,
    this.method = CheckInMethod.manual,
    this.proofImage,
  });

  @override
  List<Object?> get props => [
        employeeId,
        companyId,
        latitude,
        longitude,
        geofenceId,
        isInsideGeofence,
        method,
        proofImage,
      ];
}

/// Event to check out
class AttendanceCheckOut extends AttendanceEvent {
  final String attendanceId;
  final double latitude;
  final double longitude;
  final bool isInsideGeofence;
  final File? proofImage;

  const AttendanceCheckOut({
    required this.attendanceId,
    required this.latitude,
    required this.longitude,
    this.isInsideGeofence = false,
    this.proofImage,
  });

  @override
  List<Object?> get props => [
        attendanceId,
        latitude,
        longitude,
        isInsideGeofence,
        proofImage,
      ];
}

/// Event to get today's attendance
class AttendanceGetToday extends AttendanceEvent {
  final String employeeId;

  const AttendanceGetToday({required this.employeeId});

  @override
  List<Object?> get props => [employeeId];
}

/// Event to get attendance history
class AttendanceGetHistory extends AttendanceEvent {
  final String employeeId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;

  const AttendanceGetHistory({
    required this.employeeId,
    this.startDate,
    this.endDate,
    this.limit = 30,
  });

  @override
  List<Object?> get props => [employeeId, startDate, endDate, limit];
}

/// Event to get attendance stats
class AttendanceGetStats extends AttendanceEvent {
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;

  const AttendanceGetStats({
    required this.employeeId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [employeeId, startDate, endDate];
}

/// Event to override attendance (admin)
class AttendanceOverride extends AttendanceEvent {
  final String attendanceId;
  final String adminId;
  final String reason;
  final AttendanceStatus? newStatus;
  final DateTime? newCheckInTime;
  final DateTime? newCheckOutTime;

  const AttendanceOverride({
    required this.attendanceId,
    required this.adminId,
    required this.reason,
    this.newStatus,
    this.newCheckInTime,
    this.newCheckOutTime,
  });

  @override
  List<Object?> get props => [
        attendanceId,
        adminId,
        reason,
        newStatus,
        newCheckInTime,
        newCheckOutTime,
      ];
}

/// Event for automatic check-in via geofence
class AttendanceAutoCheckIn extends AttendanceEvent {
  final String employeeId;
  final String companyId;
  final double latitude;
  final double longitude;
  final String geofenceId;

  const AttendanceAutoCheckIn({
    required this.employeeId,
    required this.companyId,
    required this.latitude,
    required this.longitude,
    required this.geofenceId,
  });

  @override
  List<Object?> get props => [
        employeeId,
        companyId,
        latitude,
        longitude,
        geofenceId,
      ];
}

/// Event for automatic check-out via geofence
class AttendanceAutoCheckOut extends AttendanceEvent {
  final String employeeId;
  final double latitude;
  final double longitude;

  const AttendanceAutoCheckOut({
    required this.employeeId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [employeeId, latitude, longitude];
}

// ============ States ============

/// Base class for attendance states
abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

/// Initial attendance state
class AttendanceInitial extends AttendanceState {}

/// Attendance loading state
class AttendanceLoading extends AttendanceState {}

/// Today's attendance loaded
class AttendanceTodayLoaded extends AttendanceState {
  final AttendanceModel? attendance;
  final bool isCheckedIn;
  final bool isCheckedOut;

  const AttendanceTodayLoaded({
    this.attendance,
    this.isCheckedIn = false,
    this.isCheckedOut = false,
  });

  @override
  List<Object?> get props => [attendance, isCheckedIn, isCheckedOut];
}

/// Check-in successful
class AttendanceCheckedIn extends AttendanceState {
  final AttendanceModel attendance;

  const AttendanceCheckedIn({required this.attendance});

  @override
  List<Object?> get props => [attendance];
}

/// Check-out successful
class AttendanceCheckedOut extends AttendanceState {
  final AttendanceModel attendance;

  const AttendanceCheckedOut({required this.attendance});

  @override
  List<Object?> get props => [attendance];
}

/// Attendance history loaded
class AttendanceHistoryLoaded extends AttendanceState {
  final List<AttendanceModel> history;

  const AttendanceHistoryLoaded({required this.history});

  @override
  List<Object?> get props => [history];
}

/// Attendance stats loaded
class AttendanceStatsLoaded extends AttendanceState {
  final AttendanceStats stats;

  const AttendanceStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

/// Attendance error state
class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ============ Controller ============

/// Attendance controller managing attendance state
class AttendanceController extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceService _attendanceService;
  final GeofenceService _geofenceService;

  AttendanceController({
    required AttendanceService attendanceService,
    required GeofenceService geofenceService,
  })  : _attendanceService = attendanceService,
        _geofenceService = geofenceService,
        super(AttendanceInitial()) {
    // Register event handlers
    on<AttendanceCheckIn>(_onCheckIn);
    on<AttendanceCheckOut>(_onCheckOut);
    on<AttendanceGetToday>(_onGetToday);
    on<AttendanceGetHistory>(_onGetHistory);
    on<AttendanceGetStats>(_onGetStats);
    on<AttendanceOverride>(_onOverride);
    on<AttendanceAutoCheckIn>(_onAutoCheckIn);
    on<AttendanceAutoCheckOut>(_onAutoCheckOut);

    // Set up geofence callbacks for automatic attendance
    _setupGeofenceCallbacks();
  }

  /// Set up callbacks for automatic attendance via geofence
  void _setupGeofenceCallbacks() {
    _geofenceService.onGeofenceEnter = (event) {
      // This will be called from native when entering a geofence
      // The actual auto check-in should be triggered from the UI
      // with employee context
    };

    _geofenceService.onGeofenceExit = (event) {
      // Similar to above
    };
  }

  /// Handle check-in
  Future<void> _onCheckIn(
    AttendanceCheckIn event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    try {
      final attendance = await _attendanceService.checkIn(
        employeeId: event.employeeId,
        companyId: event.companyId,
        latitude: event.latitude,
        longitude: event.longitude,
        geofenceId: event.geofenceId,
        isInsideGeofence: event.isInsideGeofence,
        method: event.method,
        proofImage: event.proofImage,
      );

      emit(AttendanceCheckedIn(attendance: attendance));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  /// Handle check-out
  Future<void> _onCheckOut(
    AttendanceCheckOut event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    try {
      final attendance = await _attendanceService.checkOut(
        attendanceId: event.attendanceId,
        latitude: event.latitude,
        longitude: event.longitude,
        isInsideGeofence: event.isInsideGeofence,
        proofImage: event.proofImage,
      );

      emit(AttendanceCheckedOut(attendance: attendance));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  /// Handle get today's attendance
  Future<void> _onGetToday(
    AttendanceGetToday event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    try {
      final attendance = await _attendanceService.getTodayAttendance(
        event.employeeId,
      );

      emit(AttendanceTodayLoaded(
        attendance: attendance,
        isCheckedIn: attendance?.isCheckedIn ?? false,
        isCheckedOut: attendance?.checkOutTime != null,
      ));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  /// Handle get attendance history
  Future<void> _onGetHistory(
    AttendanceGetHistory event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    try {
      final history = await _attendanceService.getAttendanceHistory(
        employeeId: event.employeeId,
        startDate: event.startDate,
        endDate: event.endDate,
        limit: event.limit,
      );

      emit(AttendanceHistoryLoaded(history: history));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  /// Handle get attendance stats
  Future<void> _onGetStats(
    AttendanceGetStats event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    try {
      final stats = await _attendanceService.getAttendanceStats(
        employeeId: event.employeeId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(AttendanceStatsLoaded(stats: stats));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  /// Handle attendance override
  Future<void> _onOverride(
    AttendanceOverride event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());

    try {
      final attendance = await _attendanceService.overrideAttendance(
        attendanceId: event.attendanceId,
        adminId: event.adminId,
        reason: event.reason,
        newStatus: event.newStatus,
        newCheckInTime: event.newCheckInTime,
        newCheckOutTime: event.newCheckOutTime,
      );

      emit(AttendanceCheckedIn(attendance: attendance));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  /// Handle automatic check-in
  Future<void> _onAutoCheckIn(
    AttendanceAutoCheckIn event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final attendance = await _attendanceService.autoCheckIn(
        employeeId: event.employeeId,
        companyId: event.companyId,
        latitude: event.latitude,
        longitude: event.longitude,
        geofenceId: event.geofenceId,
      );

      if (attendance != null) {
        emit(AttendanceCheckedIn(attendance: attendance));
      }
    } catch (e) {
      // Silent failure for auto check-in
      // ignore: avoid_print
      print('Auto check-in failed: $e');
    }
  }

  /// Handle automatic check-out
  Future<void> _onAutoCheckOut(
    AttendanceAutoCheckOut event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final attendance = await _attendanceService.autoCheckOut(
        employeeId: event.employeeId,
        latitude: event.latitude,
        longitude: event.longitude,
      );

      if (attendance != null) {
        emit(AttendanceCheckedOut(attendance: attendance));
      }
    } catch (e) {
      // Silent failure for auto check-out
      // ignore: avoid_print
      print('Auto check-out failed: $e');
    }
  }
}
