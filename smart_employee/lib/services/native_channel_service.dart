// native_channel_service.dart
// Native Platform Channel Service
// 
// This service provides communication between Flutter and native Android/iOS
// code through MethodChannels and EventChannels. It handles:
// - Background location service control
// - Geofencing operations
// - Permission management
// - Robust reconnection handling
//
// Platform-specific notes:
// - Android: Full support with foreground service
// - iOS: Limited background location support due to platform restrictions

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Native channel service for platform communication
class NativeChannelService {
  // Singleton pattern
  static final NativeChannelService _instance = NativeChannelService._internal();
  factory NativeChannelService() => _instance;
  NativeChannelService._internal();

  // Channel names
  static const String _locationControlChannel =
      'com.example.smart_employee/location_control';
  static const String _locationStreamChannel =
      'com.example.smart_employee/location_stream';
  static const String _geofenceControlChannel =
      'com.example.smart_employee/geofence_control';
  static const String _geofenceStreamChannel =
      'com.example.smart_employee/geofence_stream';

  // Method channels
  late final MethodChannel _locationMethodChannel;
  late final MethodChannel _geofenceMethodChannel;

  // Event channels
  late final EventChannel _locationEventChannel;
  late final EventChannel _geofenceEventChannel;

  // Stream subscriptions
  StreamSubscription<dynamic>? _locationSubscription;
  StreamSubscription<dynamic>? _geofenceSubscription;

  // Stream controllers for broadcasting
  final _locationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _geofenceStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Connection state
  bool _isInitialized = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  /// Initialize the native channels
  Future<void> initialize() async {
    if (_isInitialized) return;

    _locationMethodChannel = const MethodChannel(_locationControlChannel);
    _geofenceMethodChannel = const MethodChannel(_geofenceControlChannel);
    _locationEventChannel = const EventChannel(_locationStreamChannel);
    _geofenceEventChannel = const EventChannel(_geofenceStreamChannel);

    // Set up method call handler for incoming calls from native
    _locationMethodChannel.setMethodCallHandler(_handleLocationMethodCall);
    _geofenceMethodChannel.setMethodCallHandler(_handleGeofenceMethodCall);

    _isInitialized = true;
  }

  /// Handle incoming method calls from native location service
  Future<dynamic> _handleLocationMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onLocationUpdate':
        final data = Map<String, dynamic>.from(call.arguments as Map);
        _locationStreamController.add(data);
        return null;
      case 'onServiceStatusChange':
        // Handle service status change
        return null;
      default:
        throw PlatformException(
          code: 'NOT_IMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  /// Handle incoming method calls from native geofence service
  Future<dynamic> _handleGeofenceMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onGeofenceEvent':
        final data = Map<String, dynamic>.from(call.arguments as Map);
        _geofenceStreamController.add(data);
        return null;
      default:
        throw PlatformException(
          code: 'NOT_IMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  // ============ Location Service Methods ============

  /// Start the background location service
  Future<bool> startLocationService({
    int intervalMs = 30000,
    int fastestIntervalMs = 15000,
    int priority = 100, // PRIORITY_HIGH_ACCURACY
  }) async {
    try {
      final result = await _locationMethodChannel.invokeMethod<bool>(
        'startService',
        {
          'intervalMs': intervalMs,
          'fastestIntervalMs': fastestIntervalMs,
          'priority': priority,
        },
      );
      if (result == true) {
        _setupLocationStream();
      }
      return result ?? false;
    } on PlatformException catch (e) {
      _handlePlatformException('startLocationService', e);
      return false;
    }
  }

  /// Stop the background location service
  Future<bool> stopLocationService() async {
    try {
      final result = await _locationMethodChannel.invokeMethod<bool>(
        'stopService',
      );
      _locationSubscription?.cancel();
      _locationSubscription = null;
      return result ?? false;
    } on PlatformException catch (e) {
      _handlePlatformException('stopLocationService', e);
      return false;
    }
  }

  /// Pause location updates
  Future<bool> pauseLocationService() async {
    try {
      final result = await _locationMethodChannel.invokeMethod<bool>(
        'pauseService',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _handlePlatformException('pauseLocationService', e);
      return false;
    }
  }

  /// Resume location updates
  Future<bool> resumeLocationService() async {
    try {
      final result = await _locationMethodChannel.invokeMethod<bool>(
        'resumeService',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _handlePlatformException('resumeLocationService', e);
      return false;
    }
  }

  /// Get current permission status
  Future<Map<String, dynamic>> getPermissionStatus() async {
    try {
      final result = await _locationMethodChannel.invokeMethod<Map>(
        'getPermissionStatus',
      );
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      _handlePlatformException('getPermissionStatus', e);
      return {'hasPermission': false, 'error': e.message};
    }
  }

  /// Request location permissions
  Future<bool> requestLocationPermissions() async {
    try {
      final result = await _locationMethodChannel.invokeMethod<bool>(
        'requestPermissions',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _handlePlatformException('requestLocationPermissions', e);
      return false;
    }
  }

  /// Get service running status
  Future<bool> isLocationServiceRunning() async {
    try {
      final result = await _locationMethodChannel.invokeMethod<bool>(
        'isServiceRunning',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _handlePlatformException('isLocationServiceRunning', e);
      return false;
    }
  }

  /// Set up location stream from EventChannel
  void _setupLocationStream() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationEventChannel
        .receiveBroadcastStream()
        .listen(
          (event) {
            if (event is Map) {
              _locationStreamController.add(Map<String, dynamic>.from(event));
            }
            _reconnectAttempts = 0;
          },
          onError: (error) {
            _handleStreamError('location', error);
          },
          onDone: () {
            _attemptReconnect('location');
          },
        );
  }

  /// Location updates stream
  Stream<Map<String, dynamic>> get locationStream =>
      _locationStreamController.stream;

  // ============ Geofence Methods ============

  /// Add a geofence
  Future<bool> addGeofence({
    required String id,
    required double latitude,
    required double longitude,
    required double radius,
    int? loiteringDelayMs,
    int? expirationMs,
    int? transitionTypes,
  }) async {
    try {
      final result = await _geofenceMethodChannel.invokeMethod<bool>(
        'addGeofence',
        {
          'id': id,
          'lat': latitude,
          'lng': longitude,
          'radius': radius,
          'loiteringDelayMs': loiteringDelayMs ?? 30000,
          'expirationMs': expirationMs ?? -1, // Never expire
          'transitionTypes': transitionTypes ?? 7, // ENTER | EXIT | DWELL
        },
      );
      if (result == true) {
        _setupGeofenceStream();
      }
      return result ?? false;
    } on PlatformException catch (e) {
      _handlePlatformException('addGeofence', e);
      return false;
    }
  }

  /// Remove a geofence by ID
  Future<bool> removeGeofence(String id) async {
    try {
      final result = await _geofenceMethodChannel.invokeMethod<bool>(
        'removeGeofence',
        {'id': id},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _handlePlatformException('removeGeofence', e);
      return false;
    }
  }

  /// Remove all geofences
  Future<bool> removeAllGeofences() async {
    try {
      final result = await _geofenceMethodChannel.invokeMethod<bool>(
        'removeAllGeofences',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _handlePlatformException('removeAllGeofences', e);
      return false;
    }
  }

  /// List all active geofences
  Future<List<Map<String, dynamic>>> listGeofences() async {
    try {
      final result = await _geofenceMethodChannel.invokeMethod<List>(
        'listGeofences',
      );
      if (result == null) return [];
      return result
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on PlatformException catch (e) {
      _handlePlatformException('listGeofences', e);
      return [];
    }
  }

  /// Set up geofence stream from EventChannel
  void _setupGeofenceStream() {
    _geofenceSubscription?.cancel();
    _geofenceSubscription = _geofenceEventChannel
        .receiveBroadcastStream()
        .listen(
          (event) {
            if (event is Map) {
              _geofenceStreamController.add(Map<String, dynamic>.from(event));
            }
            _reconnectAttempts = 0;
          },
          onError: (error) {
            _handleStreamError('geofence', error);
          },
          onDone: () {
            _attemptReconnect('geofence');
          },
        );
  }

  /// Geofence events stream (enter/exit/dwell)
  Stream<Map<String, dynamic>> get geofenceStream =>
      _geofenceStreamController.stream;

  // ============ Battery Optimization Methods ============

  /// Check if battery optimization is disabled for this app
  Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _locationMethodChannel.invokeMethod<bool>(
        'isBatteryOptimizationDisabled',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _handlePlatformException('isBatteryOptimizationDisabled', e);
      return false;
    }
  }

  /// Request to disable battery optimization
  Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    try {
      await _locationMethodChannel.invokeMethod(
        'requestDisableBatteryOptimization',
      );
    } on PlatformException catch (e) {
      _handlePlatformException('requestDisableBatteryOptimization', e);
    }
  }

  // ============ Error Handling & Reconnection ============

  /// Handle platform exceptions
  void _handlePlatformException(String method, PlatformException e) {
    // Log error - in production, send to crash reporting service
    // ignore: avoid_print
    print('NativeChannelService.$method error: ${e.code} - ${e.message}');
  }

  /// Handle stream errors
  void _handleStreamError(String streamType, dynamic error) {
    // Log error
    // ignore: avoid_print
    print('NativeChannelService.$streamType stream error: $error');
    _attemptReconnect(streamType);
  }

  /// Attempt to reconnect a stream
  Future<void> _attemptReconnect(String streamType) async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      // ignore: avoid_print
      print('Max reconnect attempts reached for $streamType stream');
      return;
    }

    _reconnectAttempts++;
    await Future.delayed(_reconnectDelay * _reconnectAttempts);

    if (streamType == 'location') {
      _setupLocationStream();
    } else if (streamType == 'geofence') {
      _setupGeofenceStream();
    }
  }

  /// Dispose resources
  void dispose() {
    _locationSubscription?.cancel();
    _geofenceSubscription?.cancel();
    _locationStreamController.close();
    _geofenceStreamController.close();
  }
}
