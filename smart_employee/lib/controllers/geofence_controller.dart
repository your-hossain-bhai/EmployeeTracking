// geofence_controller.dart
// Geofence Controller (BLoC)
//
// This controller manages geofence state using flutter_bloc.
// It handles adding, removing, and monitoring geofences.

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../services/geofence_service.dart';
import '../models/geofence_model.dart';

// Alias to avoid naming conflict
typedef GeofenceServiceEvent = GeofenceEvent;

// ============ Events ============

/// Base class for geofence BLoC events
abstract class GeofenceBlocEvent extends Equatable {
  const GeofenceBlocEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all geofences
class GeofenceLoadAll extends GeofenceBlocEvent {
  final String companyId;

  const GeofenceLoadAll({required this.companyId});

  @override
  List<Object?> get props => [companyId];
}

/// Event to add a new geofence
class GeofenceAdd extends GeofenceBlocEvent {
  final String companyId;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final GeofenceType type;
  final String? description;
  final String? address;
  final String? createdBy;

  const GeofenceAdd({
    required this.companyId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.type = GeofenceType.office,
    this.description,
    this.address,
    this.createdBy,
  });

  @override
  List<Object?> get props => [
        companyId,
        name,
        latitude,
        longitude,
        radius,
        type,
        description,
        address,
        createdBy,
      ];
}

/// Event to update a geofence
class GeofenceUpdate extends GeofenceBlocEvent {
  final GeofenceModel geofence;

  const GeofenceUpdate({required this.geofence});

  @override
  List<Object?> get props => [geofence];
}

/// Event to remove a geofence
class GeofenceRemove extends GeofenceBlocEvent {
  final String geofenceId;

  const GeofenceRemove({required this.geofenceId});

  @override
  List<Object?> get props => [geofenceId];
}

/// Event to register all geofences with native
class GeofenceRegisterAll extends GeofenceBlocEvent {
  final String companyId;

  const GeofenceRegisterAll({required this.companyId});

  @override
  List<Object?> get props => [companyId];
}

/// Event to unregister all geofences
class GeofenceUnregisterAll extends GeofenceBlocEvent {}

/// Event when a geofence transition occurs
class GeofenceTransition extends GeofenceBlocEvent {
  final GeofenceServiceEvent event;

  const GeofenceTransition({required this.event});

  @override
  List<Object?> get props => [event];
}

// ============ States ============

/// Base class for geofence states
abstract class GeofenceState extends Equatable {
  const GeofenceState();

  @override
  List<Object?> get props => [];
}

/// Initial geofence state
class GeofenceInitial extends GeofenceState {}

/// Geofence loading state
class GeofenceLoading extends GeofenceState {}

/// Geofences loaded
class GeofenceLoaded extends GeofenceState {
  final List<GeofenceModel> geofences;

  const GeofenceLoaded({required this.geofences});

  @override
  List<Object?> get props => [geofences];
}

/// Geofence added successfully
class GeofenceAdded extends GeofenceState {
  final GeofenceModel geofence;

  const GeofenceAdded({required this.geofence});

  @override
  List<Object?> get props => [geofence];
}

/// Geofence updated successfully
class GeofenceUpdated extends GeofenceState {
  final GeofenceModel geofence;

  const GeofenceUpdated({required this.geofence});

  @override
  List<Object?> get props => [geofence];
}

/// Geofence removed successfully
class GeofenceRemoved extends GeofenceState {
  final String geofenceId;

  const GeofenceRemoved({required this.geofenceId});

  @override
  List<Object?> get props => [geofenceId];
}

/// Geofence registration status
class GeofenceRegistrationStatus extends GeofenceState {
  final bool isRegistered;
  final int count;

  const GeofenceRegistrationStatus({
    required this.isRegistered,
    required this.count,
  });

  @override
  List<Object?> get props => [isRegistered, count];
}

/// Geofence event occurred
class GeofenceEventOccurred extends GeofenceState {
  final String geofenceId;
  final GeofenceEventType type;
  final DateTime timestamp;

  const GeofenceEventOccurred({
    required this.geofenceId,
    required this.type,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [geofenceId, type, timestamp];
}

/// Geofence error state
class GeofenceError extends GeofenceState {
  final String message;

  const GeofenceError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ============ Controller ============

/// Geofence controller managing geofence state
class GeofenceController extends Bloc<GeofenceBlocEvent, GeofenceState> {
  final GeofenceService _geofenceService;
  StreamSubscription<GeofenceServiceEvent>? _eventSubscription;
  List<GeofenceModel> _currentGeofences = [];

  GeofenceController({
    required GeofenceService geofenceService,
  })  : _geofenceService = geofenceService,
        super(GeofenceInitial()) {
    // Register event handlers
    on<GeofenceLoadAll>(_onLoadAll);
    on<GeofenceAdd>(_onAdd);
    on<GeofenceUpdate>(_onUpdate);
    on<GeofenceRemove>(_onRemove);
    on<GeofenceRegisterAll>(_onRegisterAll);
    on<GeofenceUnregisterAll>(_onUnregisterAll);

    // Listen to geofence events
    _eventSubscription = _geofenceService.geofenceEvents.listen(
      (event) {
        // Handle geofence transitions
      },
    );
  }

  /// Current list of geofences
  List<GeofenceModel> get geofences => _currentGeofences;

  /// Handle load all geofences
  Future<void> _onLoadAll(
    GeofenceLoadAll event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(GeofenceLoading());

    try {
      _currentGeofences = await _geofenceService.getGeofences(event.companyId);
      emit(GeofenceLoaded(geofences: _currentGeofences));
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  /// Handle add geofence
  Future<void> _onAdd(
    GeofenceAdd event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(GeofenceLoading());

    try {
      final geofence = await _geofenceService.addGeofence(
        companyId: event.companyId,
        name: event.name,
        latitude: event.latitude,
        longitude: event.longitude,
        radius: event.radius,
        type: event.type,
        description: event.description,
        address: event.address,
        createdBy: event.createdBy,
      );

      _currentGeofences.add(geofence);
      emit(GeofenceAdded(geofence: geofence));
      emit(GeofenceLoaded(geofences: _currentGeofences));
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  /// Handle update geofence
  Future<void> _onUpdate(
    GeofenceUpdate event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(GeofenceLoading());

    try {
      final updated = await _geofenceService.updateGeofence(event.geofence);

      final index = _currentGeofences.indexWhere((g) => g.id == updated.id);
      if (index != -1) {
        _currentGeofences[index] = updated;
      }

      emit(GeofenceUpdated(geofence: updated));
      emit(GeofenceLoaded(geofences: _currentGeofences));
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  /// Handle remove geofence
  Future<void> _onRemove(
    GeofenceRemove event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(GeofenceLoading());

    try {
      await _geofenceService.removeGeofence(event.geofenceId);

      _currentGeofences.removeWhere((g) => g.id == event.geofenceId);
      emit(GeofenceRemoved(geofenceId: event.geofenceId));
      emit(GeofenceLoaded(geofences: _currentGeofences));
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  /// Handle register all geofences
  Future<void> _onRegisterAll(
    GeofenceRegisterAll event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(GeofenceLoading());

    try {
      await _geofenceService.registerAllGeofences(event.companyId);

      final nativeGeofences = await _geofenceService.listNativeGeofences();
      emit(GeofenceRegistrationStatus(
        isRegistered: true,
        count: nativeGeofences.length,
      ));
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  /// Handle unregister all geofences
  Future<void> _onUnregisterAll(
    GeofenceUnregisterAll event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(GeofenceLoading());

    try {
      await _geofenceService.unregisterAllGeofences();

      emit(const GeofenceRegistrationStatus(
        isRegistered: false,
        count: 0,
      ));
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  /// Find geofence by ID
  GeofenceModel? findGeofence(String id) {
    return _currentGeofences.where((g) => g.id == id).firstOrNull;
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    return super.close();
  }
}
