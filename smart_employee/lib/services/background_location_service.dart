// background_location_service.dart
// Background Location Service
// 
// This service coordinates background location tracking by integrating
// with the native Android LocationService via NativeChannelService.
// It manages location updates and uploads them to Firestore.
//
// Features:
// - Coordinates native background service
// - Uploads location data to Firestore (configurable: Flutter or native upload)
// - Local caching with Hive for offline support
// - Battery-efficient tracking with configurable intervals
//
// NOTE: Default is Flutter-based upload for better control and offline handling.
// Set useNativeUpload=true in startTracking() to use native Firestore upload.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import 'native_channel_service.dart';
import '../models/location_model.dart';

/// Background location service for coordinating location tracking
class BackgroundLocationService {
  final NativeChannelService _nativeChannelService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late final Box _locationBox;
  StreamSubscription<Map<String, dynamic>>? _locationSubscription;
  
  String? _currentEmployeeId;
  bool _isTracking = false;
  bool _useNativeUpload = false;
  
  // Batch upload settings
  static const int _batchSize = 10;
  static const Duration _batchUploadInterval = Duration(minutes: 5);
  Timer? _batchUploadTimer;
  final List<LocationModel> _pendingLocations = [];

  BackgroundLocationService(this._nativeChannelService);

  /// Initialize the service
  Future<void> initialize() async {
    _locationBox = Hive.box('locations');
  }

  /// Start background location tracking
  /// 
  /// [employeeId] - The ID of the employee being tracked
  /// [intervalSeconds] - Location update interval in seconds (default: 30)
  /// [useNativeUpload] - If true, uploads occur in native code (default: false)
  Future<bool> startTracking({
    required String employeeId,
    int intervalSeconds = 30,
    bool useNativeUpload = false,
  }) async {
    if (_isTracking) {
      return true;
    }

    _currentEmployeeId = employeeId;
    _useNativeUpload = useNativeUpload;

    // Start native location service
    final started = await _nativeChannelService.startLocationService(
      intervalMs: intervalSeconds * 1000,
      fastestIntervalMs: (intervalSeconds * 1000) ~/ 2,
    );

    if (started) {
      _isTracking = true;
      
      // Listen to location updates
      _locationSubscription = _nativeChannelService.locationStream.listen(
        _handleLocationUpdate,
        onError: _handleError,
      );

      // Start batch upload timer if using Flutter upload
      if (!_useNativeUpload) {
        _startBatchUploadTimer();
      }
    }

    return started;
  }

  /// Stop background location tracking
  Future<bool> stopTracking() async {
    _isTracking = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _batchUploadTimer?.cancel();
    _batchUploadTimer = null;

    // Upload any pending locations
    await _uploadPendingLocations();

    return await _nativeChannelService.stopLocationService();
  }

  /// Pause location tracking
  Future<bool> pauseTracking() async {
    return await _nativeChannelService.pauseLocationService();
  }

  /// Resume location tracking
  Future<bool> resumeTracking() async {
    return await _nativeChannelService.resumeLocationService();
  }

  /// Check if tracking is active
  bool get isTracking => _isTracking;

  /// Handle incoming location updates
  void _handleLocationUpdate(Map<String, dynamic> data) {
    if (_currentEmployeeId == null) return;

    final location = LocationModel.fromNativeData(data, _currentEmployeeId!);
    
    // Save to local storage first
    _saveToLocal(location);

    if (!_useNativeUpload) {
      // Add to pending batch
      _pendingLocations.add(location);

      // Upload immediately if batch is full
      if (_pendingLocations.length >= _batchSize) {
        _uploadPendingLocations();
      }
    }
  }

  /// Save location to local Hive storage
  Future<void> _saveToLocal(LocationModel location) async {
    try {
      await _locationBox.put(location.id, location.toJson());
    } catch (e) {
      // ignore: avoid_print
      print('Error saving location to local storage: $e');
    }
  }

  /// Start the batch upload timer
  void _startBatchUploadTimer() {
    _batchUploadTimer?.cancel();
    _batchUploadTimer = Timer.periodic(_batchUploadInterval, (_) {
      _uploadPendingLocations();
    });
  }

  /// Upload pending locations to Firestore
  Future<void> _uploadPendingLocations() async {
    if (_pendingLocations.isEmpty) return;

    final locationsToUpload = List<LocationModel>.from(_pendingLocations);
    _pendingLocations.clear();

    try {
      // Use batch write for efficiency
      final batch = _firestore.batch();
      
      for (final location in locationsToUpload) {
        final docRef = _firestore
            .collection('locations')
            .doc(location.id);
        batch.set(docRef, location.toFirestore());
      }

      await batch.commit();

      // Mark as synced in local storage
      for (final location in locationsToUpload) {
        final syncedLocation = location.copyWith(isSynced: true);
        await _locationBox.put(location.id, syncedLocation.toJson());
      }
    } catch (e) {
      // Re-add to pending for retry
      _pendingLocations.addAll(locationsToUpload);
      // ignore: avoid_print
      print('Error uploading locations to Firestore: $e');
    }
  }

  /// Sync unsynced locations from local storage
  Future<void> syncUnsyncedLocations() async {
    try {
      final allLocations = _locationBox.values
          .map((e) => LocationModel.fromJson(Map<String, dynamic>.from(e)))
          .where((loc) => !loc.isSynced)
          .toList();

      if (allLocations.isEmpty) return;

      // Upload in batches
      for (var i = 0; i < allLocations.length; i += _batchSize) {
        final batch = allLocations.skip(i).take(_batchSize).toList();
        final firestoreBatch = _firestore.batch();

        for (final location in batch) {
          final docRef = _firestore.collection('locations').doc(location.id);
          firestoreBatch.set(docRef, location.toFirestore());
        }

        await firestoreBatch.commit();

        // Mark as synced
        for (final location in batch) {
          final syncedLocation = location.copyWith(isSynced: true);
          await _locationBox.put(location.id, syncedLocation.toJson());
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error syncing unsynced locations: $e');
    }
  }

  /// Get location history for an employee
  Future<List<LocationModel>> getLocationHistory({
    required String employeeId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection('locations')
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

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

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Fallback to local storage
      return _getLocalLocationHistory(employeeId, startDate, endDate, limit);
    }
  }

  /// Get location history from local storage
  List<LocationModel> _getLocalLocationHistory(
    String employeeId,
    DateTime? startDate,
    DateTime? endDate,
    int limit,
  ) {
    return _locationBox.values
        .map((e) => LocationModel.fromJson(Map<String, dynamic>.from(e)))
        .where((loc) {
          if (loc.employeeId != employeeId) return false;
          if (startDate != null && loc.timestamp.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && loc.timestamp.isAfter(endDate)) {
            return false;
          }
          return true;
        })
        .take(limit)
        .toList();
  }

  /// Delete old location data (for privacy/retention policy)
  Future<void> deleteOldLocations(Duration retentionPeriod) async {
    final cutoffDate = DateTime.now().subtract(retentionPeriod);

    try {
      // Delete from Firestore
      final snapshot = await _firestore
          .collection('locations')
          .where('employeeId', isEqualTo: _currentEmployeeId)
          .where(
            'timestamp',
            isLessThan: Timestamp.fromDate(cutoffDate),
          )
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete from local storage
      final keysToDelete = _locationBox.values
          .map((e) => LocationModel.fromJson(Map<String, dynamic>.from(e)))
          .where((loc) => loc.timestamp.isBefore(cutoffDate))
          .map((loc) => loc.id)
          .toList();

      for (final key in keysToDelete) {
        await _locationBox.delete(key);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting old locations: $e');
    }
  }

  /// Handle stream errors
  void _handleError(dynamic error) {
    // ignore: avoid_print
    print('BackgroundLocationService error: $error');
  }

  /// Dispose resources
  void dispose() {
    _locationSubscription?.cancel();
    _batchUploadTimer?.cancel();
  }
}
