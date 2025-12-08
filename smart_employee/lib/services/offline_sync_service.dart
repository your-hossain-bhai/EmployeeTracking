// offline_sync_service.dart
// Offline Sync Service
// 
// This service manages offline data synchronization between
// local Hive storage and Firestore. It monitors connectivity
// and syncs pending data when a connection is available.
//
// Features:
// - Monitors network connectivity
// - Syncs pending locations, attendance, and other data
// - Handles conflict resolution
// - Queue-based upload with retry logic

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../models/location_model.dart';
import '../models/attendance_model.dart';

/// Sync status for tracking sync state
enum SyncStatus { idle, syncing, error, completed }

/// Offline sync service for managing local-remote data synchronization
class OfflineSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  
  bool _isSyncing = false;
  bool _isOnline = false;
  Timer? _periodicSyncTimer;

  static const Duration _periodicSyncInterval = Duration(minutes: 15);
  static const int _maxRetries = 3;

  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Current connectivity status
  bool get isOnline => _isOnline;

  /// Start monitoring connectivity and syncing
  void startSyncMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    // Check initial connectivity
    _checkConnectivity();

    // Start periodic sync
    _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (_) {
      if (_isOnline && !_isSyncing) {
        syncAll();
      }
    });
  }

  /// Stop sync monitoring
  void stopSyncMonitoring() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }

  /// Check current connectivity
  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _handleConnectivityChange(result);
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.isNotEmpty && 
        !results.contains(ConnectivityResult.none);

    // Sync when coming back online
    if (!wasOnline && _isOnline) {
      syncAll();
    }
  }

  /// Sync all pending data
  Future<void> syncAll() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      await Future.wait([
        _syncLocations(),
        _syncAttendance(),
      ]);
      _syncStatusController.add(SyncStatus.completed);
    } catch (e) {
      _syncStatusController.add(SyncStatus.error);
      // ignore: avoid_print
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync pending locations
  Future<void> _syncLocations() async {
    final box = Hive.box('locations');
    final unsyncedLocations = box.values
        .map((e) => LocationModel.fromJson(Map<String, dynamic>.from(e)))
        .where((loc) => !loc.isSynced)
        .toList();

    if (unsyncedLocations.isEmpty) return;

    // Process in batches
    const batchSize = 50;
    for (var i = 0; i < unsyncedLocations.length; i += batchSize) {
      final batch = unsyncedLocations.skip(i).take(batchSize).toList();
      
      int retries = 0;
      bool success = false;

      while (!success && retries < _maxRetries) {
        try {
          final firestoreBatch = _firestore.batch();
          
          for (final location in batch) {
            final docRef = _firestore.collection('locations').doc(location.id);
            firestoreBatch.set(docRef, location.toFirestore(), SetOptions(merge: true));
          }

          await firestoreBatch.commit();

          // Mark as synced
          for (final location in batch) {
            final synced = location.copyWith(isSynced: true);
            await box.put(location.id, synced.toJson());
          }

          success = true;
        } catch (e) {
          retries++;
          if (retries < _maxRetries) {
            await Future.delayed(Duration(seconds: retries * 2));
          }
        }
      }
    }
  }

  /// Sync pending attendance records
  Future<void> _syncAttendance() async {
    final box = Hive.box('attendance');
    final unsyncedAttendance = box.values
        .map((e) => AttendanceModel.fromJson(Map<String, dynamic>.from(e)))
        .where((att) => !att.isSynced)
        .toList();

    if (unsyncedAttendance.isEmpty) return;

    for (final attendance in unsyncedAttendance) {
      int retries = 0;
      bool success = false;

      while (!success && retries < _maxRetries) {
        try {
          await _firestore
              .collection('attendance')
              .doc(attendance.id)
              .set(attendance.toFirestore(), SetOptions(merge: true));

          // Mark as synced
          final synced = attendance.copyWith(isSynced: true);
          await box.put(attendance.id, synced.toJson());

          success = true;
        } catch (e) {
          retries++;
          if (retries < _maxRetries) {
            await Future.delayed(Duration(seconds: retries * 2));
          }
        }
      }
    }
  }

  /// Queue data for sync
  Future<void> queueForSync({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final box = Hive.box(collection);
    await box.put(id, {...data, 'isSynced': false});

    // Try to sync immediately if online
    if (_isOnline && !_isSyncing) {
      syncAll();
    }
  }

  /// Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    final stats = <String, int>{};

    // Locations
    final locationBox = Hive.box('locations');
    final unsyncedLocations = locationBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .where((loc) => !(loc['isSynced'] ?? false))
        .length;
    stats['unsyncedLocations'] = unsyncedLocations;

    // Attendance
    final attendanceBox = Hive.box('attendance');
    final unsyncedAttendance = attendanceBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .where((att) => !(att['isSynced'] ?? false))
        .length;
    stats['unsyncedAttendance'] = unsyncedAttendance;

    return stats;
  }

  /// Force sync specific collection
  Future<void> syncCollection(String collection) async {
    if (!_isOnline) return;

    switch (collection) {
      case 'locations':
        await _syncLocations();
        break;
      case 'attendance':
        await _syncAttendance();
        break;
    }
  }

  /// Clear all local data
  Future<void> clearLocalData() async {
    final boxes = ['locations', 'attendance', 'employees', 'geofences'];
    for (final boxName in boxes) {
      final box = Hive.box(boxName);
      await box.clear();
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _syncStatusController.close();
  }
}
