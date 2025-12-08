// location_controller.dart
// Location Controller (BLoC)
// 
// This controller manages location tracking state using flutter_bloc.
// It handles starting/stopping tracking, location updates, and history.

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../services/native_channel_service.dart';
import '../models/location_model.dart';

// ============ Events ============

/// Base class for location events
abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start location tracking
class LocationStartTracking extends LocationEvent {
  final String employeeId;
  final int intervalSeconds;

  const LocationStartTracking({
    required this.employeeId,
    this.intervalSeconds = 30,
  });

  @override
  List<Object?> get props => [employeeId, intervalSeconds];
}

/// Event to stop location tracking
class LocationStopTracking extends LocationEvent {}

/// Event to pause location tracking
class LocationPauseTracking extends LocationEvent {}

/// Event to resume location tracking
class LocationResumeTracking extends LocationEvent {}

/// Event when location is updated
class LocationUpdated extends LocationEvent {
  final LocationModel location;

  const LocationUpdated({required this.location});

  @override
  List<Object?> get props => [location];
}

/// Event to get current location
class LocationGetCurrent extends LocationEvent {}

/// Event to get location history
class LocationGetHistory extends LocationEvent {
  final String employeeId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;

  const LocationGetHistory({
    required this.employeeId,
    this.startDate,
    this.endDate,
    this.limit = 100,
  });

  @override
  List<Object?> get props => [employeeId, startDate, endDate, limit];
}

/// Event to check permissions
class LocationCheckPermissions extends LocationEvent {}

/// Event to request permissions
class LocationRequestPermissions extends LocationEvent {}

// ============ States ============

/// Base class for location states
abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

/// Initial location state
class LocationInitial extends LocationState {}

/// Location loading state
class LocationLoading extends LocationState {}

/// Location tracking is active
class LocationTrackingActive extends LocationState {
  final LocationModel? currentLocation;
  final bool isPaused;

  const LocationTrackingActive({
    this.currentLocation,
    this.isPaused = false,
  });

  @override
  List<Object?> get props => [currentLocation, isPaused];
}

/// Location tracking is inactive
class LocationTrackingInactive extends LocationState {}

/// Location history loaded
class LocationHistoryLoaded extends LocationState {
  final List<LocationModel> locations;

  const LocationHistoryLoaded({required this.locations});

  @override
  List<Object?> get props => [locations];
}

/// Current location obtained
class LocationCurrentObtained extends LocationState {
  final Position position;

  const LocationCurrentObtained({required this.position});

  @override
  List<Object?> get props => [position];
}

/// Location permissions state
class LocationPermissionState extends LocationState {
  final bool hasPermission;
  final bool serviceEnabled;
  final String? message;

  const LocationPermissionState({
    required this.hasPermission,
    required this.serviceEnabled,
    this.message,
  });

  @override
  List<Object?> get props => [hasPermission, serviceEnabled, message];
}

/// Location error state
class LocationError extends LocationState {
  final String message;

  const LocationError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ============ Controller ============

/// Location controller managing location tracking state
class LocationController extends Bloc<LocationEvent, LocationState> {
  final LocationService _locationService;
  final NativeChannelService _nativeChannelService;

  StreamSubscription<Map<String, dynamic>>? _locationSubscription;
  String? _currentEmployeeId;
  bool _isTracking = false;
  bool _isPaused = false;

  LocationController({
    required LocationService locationService,
    required NativeChannelService nativeChannelService,
  })  : _locationService = locationService,
        _nativeChannelService = nativeChannelService,
        super(LocationInitial()) {
    // Register event handlers
    on<LocationStartTracking>(_onStartTracking);
    on<LocationStopTracking>(_onStopTracking);
    on<LocationPauseTracking>(_onPauseTracking);
    on<LocationResumeTracking>(_onResumeTracking);
    on<LocationUpdated>(_onLocationUpdated);
    on<LocationGetCurrent>(_onGetCurrent);
    on<LocationGetHistory>(_onGetHistory);
    on<LocationCheckPermissions>(_onCheckPermissions);
    on<LocationRequestPermissions>(_onRequestPermissions);
  }

  /// Handle start tracking
  Future<void> _onStartTracking(
    LocationStartTracking event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    try {
      _currentEmployeeId = event.employeeId;

      // Start native location service
      final started = await _nativeChannelService.startLocationService(
        intervalMs: event.intervalSeconds * 1000,
      );

      if (started) {
        _isTracking = true;
        _isPaused = false;

        // Listen to location updates
        _locationSubscription?.cancel();
        _locationSubscription = _nativeChannelService.locationStream.listen(
          (data) {
            if (_currentEmployeeId != null) {
              final location = LocationModel.fromNativeData(
                data,
                _currentEmployeeId!,
              );
              add(LocationUpdated(location: location));
            }
          },
        );

        emit(const LocationTrackingActive());
      } else {
        emit(const LocationError(message: 'Failed to start location service'));
      }
    } catch (e) {
      emit(LocationError(message: e.toString()));
    }
  }

  /// Handle stop tracking
  Future<void> _onStopTracking(
    LocationStopTracking event,
    Emitter<LocationState> emit,
  ) async {
    try {
      await _nativeChannelService.stopLocationService();
      _locationSubscription?.cancel();
      _locationSubscription = null;
      _isTracking = false;
      _isPaused = false;
      _currentEmployeeId = null;

      emit(LocationTrackingInactive());
    } catch (e) {
      emit(LocationError(message: e.toString()));
    }
  }

  /// Handle pause tracking
  Future<void> _onPauseTracking(
    LocationPauseTracking event,
    Emitter<LocationState> emit,
  ) async {
    try {
      await _nativeChannelService.pauseLocationService();
      _isPaused = true;

      final currentState = state;
      if (currentState is LocationTrackingActive) {
        emit(LocationTrackingActive(
          currentLocation: currentState.currentLocation,
          isPaused: true,
        ));
      }
    } catch (e) {
      emit(LocationError(message: e.toString()));
    }
  }

  /// Handle resume tracking
  Future<void> _onResumeTracking(
    LocationResumeTracking event,
    Emitter<LocationState> emit,
  ) async {
    try {
      await _nativeChannelService.resumeLocationService();
      _isPaused = false;

      final currentState = state;
      if (currentState is LocationTrackingActive) {
        emit(LocationTrackingActive(
          currentLocation: currentState.currentLocation,
          isPaused: false,
        ));
      }
    } catch (e) {
      emit(LocationError(message: e.toString()));
    }
  }

  /// Handle location update
  void _onLocationUpdated(
    LocationUpdated event,
    Emitter<LocationState> emit,
  ) {
    if (_isTracking) {
      emit(LocationTrackingActive(
        currentLocation: event.location,
        isPaused: _isPaused,
      ));
    }
  }

  /// Handle get current location
  Future<void> _onGetCurrent(
    LocationGetCurrent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        emit(LocationCurrentObtained(position: position));
      } else {
        emit(const LocationError(message: 'Could not get current location'));
      }
    } catch (e) {
      emit(LocationError(message: e.toString()));
    }
  }

  /// Handle get location history
  Future<void> _onGetHistory(
    LocationGetHistory event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    try {
      final locations = await _locationService.getLocationHistory(
        employeeId: event.employeeId,
        startDate: event.startDate,
        endDate: event.endDate,
        limit: event.limit,
      );

      emit(LocationHistoryLoaded(locations: locations));
    } catch (e) {
      emit(LocationError(message: e.toString()));
    }
  }

  /// Handle check permissions
  Future<void> _onCheckPermissions(
    LocationCheckPermissions event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      final permission = await _locationService.checkPermission();

      final hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      String? message;
      if (!serviceEnabled) {
        message = 'Location services are disabled';
      } else if (!hasPermission) {
        message = 'Location permission is required';
      }

      emit(LocationPermissionState(
        hasPermission: hasPermission,
        serviceEnabled: serviceEnabled,
        message: message,
      ));
    } catch (e) {
      emit(LocationError(message: e.toString()));
    }
  }

  /// Handle request permissions
  Future<void> _onRequestPermissions(
    LocationRequestPermissions event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _locationService.openLocationSettings();
        return;
      }

      final permission = await _locationService.requestPermission();
      final hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      emit(LocationPermissionState(
        hasPermission: hasPermission,
        serviceEnabled: serviceEnabled,
      ));
    } catch (e) {
      emit(LocationError(message: e.toString()));
    }
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Check if tracking is paused
  bool get isPaused => _isPaused;

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
