// geofence_service.dart
// Geofence Service
//
// This service manages geofence operations including:
// - Adding/removing geofences via native Android GeofencingClient
// - Monitoring geofence enter/exit events
// - Triggering automatic attendance
// - Syncing geofences with Firestore

import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'native_channel_service.dart';
import '../models/geofence_model.dart';

/// Geofence event types
enum GeofenceEventType { enter, exit, dwell }

/// Geofence event data
class GeofenceEvent {
  final String geofenceId;
  final GeofenceEventType type;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  GeofenceEvent({
    required this.geofenceId,
    required this.type,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  factory GeofenceEvent.fromNativeData(Map<String, dynamic> data) {
    return GeofenceEvent(
      geofenceId: data['geofenceId'] ?? '',
      type: GeofenceEventType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => GeofenceEventType.enter,
      ),
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int)
          : DateTime.now(),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }
}

/// Geofence service for managing geofence operations
class GeofenceService {
  final NativeChannelService _nativeChannelService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  late final Box _geofenceBox;
  bool _isInitialized = false;

  StreamSubscription<Map<String, dynamic>>? _geofenceEventSubscription;
  final _geofenceEventController = StreamController<GeofenceEvent>.broadcast();

  // Callbacks for automatic attendance
  Function(GeofenceEvent)? onGeofenceEnter;
  Function(GeofenceEvent)? onGeofenceExit;

  GeofenceService(this._nativeChannelService);

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _geofenceBox = Hive.box('geofences');
    _isInitialized = true;

    // Listen to native geofence events
    _geofenceEventSubscription = _nativeChannelService.geofenceStream.listen(
      _handleGeofenceEvent,
    );
  }

  /// Stream of geofence events
  Stream<GeofenceEvent> get geofenceEvents => _geofenceEventController.stream;

  /// Handle incoming geofence events from native
  void _handleGeofenceEvent(Map<String, dynamic> data) {
    final event = GeofenceEvent.fromNativeData(data);
    _geofenceEventController.add(event);

    // Trigger callbacks
    if (event.type == GeofenceEventType.enter) {
      onGeofenceEnter?.call(event);
    } else if (event.type == GeofenceEventType.exit) {
      onGeofenceExit?.call(event);
    }
  }

  /// Add a new geofence
  Future<GeofenceModel> addGeofence({
    required String companyId,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    GeofenceType type = GeofenceType.office,
    String? description,
    String? address,
    String? workStartTime,
    String? workEndTime,
    List<int>? workDays,
    bool autoCheckIn = true,
    bool autoCheckOut = true,
    String? createdBy,
  }) async {
    final now = DateTime.now();
    final geofence = GeofenceModel(
      id: _uuid.v4(),
      companyId: companyId,
      name: name,
      description: description,
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: type,
      address: address,
      workStartTime: workStartTime,
      workEndTime: workEndTime,
      workDays: workDays,
      autoCheckIn: autoCheckIn,
      autoCheckOut: autoCheckOut,
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
    );

    // Try to add to native geofencing (optional - will work without it)
    try {
      await _nativeChannelService.addGeofence(
        id: geofence.id,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
    } catch (e) {
      // Native geofencing failed - continue anyway
      // Geofence will still work via distance calculations
      debugPrint('Native geofencing not available: $e');
    }

    // Save to Firestore
    await _firestore
        .collection('geofences')
        .doc(geofence.id)
        .set(geofence.toFirestore());

    // Save to local storage
    await _saveToLocal(geofence);

    return geofence;
  }

  /// Update an existing geofence
  Future<GeofenceModel> updateGeofence(GeofenceModel geofence) async {
    final updated = geofence.copyWith(updatedAt: DateTime.now());

    // Try to update native geofencing (optional)
    try {
      await _nativeChannelService.removeGeofence(geofence.id);
      await _nativeChannelService.addGeofence(
        id: geofence.id,
        latitude: geofence.latitude,
        longitude: geofence.longitude,
        radius: geofence.radius,
      );
    } catch (e) {
      debugPrint('Native geofencing update failed: $e');
    }

    // Update Firestore
    await _firestore
        .collection('geofences')
        .doc(geofence.id)
        .update(updated.toFirestore());

    // Update local storage
    await _saveToLocal(updated);

    return updated;
  }

  /// Remove a geofence
  Future<void> removeGeofence(String geofenceId) async {
    // Try to remove from native (optional)
    try {
      await _nativeChannelService.removeGeofence(geofenceId);
    } catch (e) {
      debugPrint('Native geofencing removal failed: $e');
    }

    // Remove from Firestore
    await _firestore.collection('geofences').doc(geofenceId).delete();

    // Remove from local storage
    await _geofenceBox.delete(geofenceId);
  }

  /// Get all geofences for a company
  Future<List<GeofenceModel>> getGeofences(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('geofences')
          .where('companyId', isEqualTo: companyId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => GeofenceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Fallback to local storage
      return _getLocalGeofences(companyId);
    }
  }

  /// Get geofences from local storage
  List<GeofenceModel> _getLocalGeofences(String companyId) {
    return _geofenceBox.values
        .map((e) => GeofenceModel.fromJson(Map<String, dynamic>.from(e)))
        .where((g) => g.companyId == companyId && g.isActive)
        .toList();
  }

  /// Get a single geofence by ID
  Future<GeofenceModel?> getGeofence(String geofenceId) async {
    try {
      final doc =
          await _firestore.collection('geofences').doc(geofenceId).get();

      if (!doc.exists) return null;
      return GeofenceModel.fromFirestore(doc);
    } catch (e) {
      // Fallback to local storage
      final local = _geofenceBox.get(geofenceId);
      if (local == null) return null;
      return GeofenceModel.fromJson(Map<String, dynamic>.from(local));
    }
  }

  /// Stream geofences for a company
  Stream<List<GeofenceModel>> streamGeofences(String companyId) {
    return _firestore
        .collection('geofences')
        .where('companyId', isEqualTo: companyId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GeofenceModel.fromFirestore(doc))
            .toList());
  }

  /// Register all geofences for a company with native service
  Future<void> registerAllGeofences(String companyId) async {
    final geofences = await getGeofences(companyId);

    for (final geofence in geofences) {
      await _nativeChannelService.addGeofence(
        id: geofence.id,
        latitude: geofence.latitude,
        longitude: geofence.longitude,
        radius: geofence.radius,
      );
    }
  }

  /// Remove all geofences from native service
  Future<void> unregisterAllGeofences() async {
    await _nativeChannelService.removeAllGeofences();
  }

  /// List currently active geofences in native
  Future<List<Map<String, dynamic>>> listNativeGeofences() async {
    return await _nativeChannelService.listGeofences();
  }

  /// Check if a location is inside any geofence
  GeofenceModel? findContainingGeofence({
    required double latitude,
    required double longitude,
    required List<GeofenceModel> geofences,
  }) {
    for (final geofence in geofences) {
      final distance = _calculateDistance(
        lat1: latitude,
        lon1: longitude,
        lat2: geofence.latitude,
        lon2: geofence.longitude,
      );

      if (distance <= geofence.radius) {
        return geofence;
      }
    }
    return null;
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * (math.pi / 180);

  /// Save geofence to local storage
  Future<void> _saveToLocal(GeofenceModel geofence) async {
    if (!_isInitialized) await initialize();
    await _geofenceBox.put(geofence.id, geofence.toJson());
  }

  /// Dispose resources
  void dispose() {
    _geofenceEventSubscription?.cancel();
    _geofenceEventController.close();
  }
}
