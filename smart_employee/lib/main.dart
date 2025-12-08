// main.dart
// Entry point for the Smart Employee application
//
// This file initializes Firebase, Hive for local storage,
// and sets up the application with proper error handling.
//
// NOTE: Ensure firebase_options.dart is generated via `flutterfire configure`
// before running the application.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'config/firebase_options.dart';
import 'services/native_channel_service.dart';
import 'services/offline_sync_service.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/attendance_service.dart';
import 'services/geofence_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/location_controller.dart';
import 'controllers/attendance_controller.dart';
import 'controllers/geofence_controller.dart';

/// Application entry point
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase (only if not already initialized)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Firebase already initialized, ignore
    debugPrint('Firebase initialization: $e');
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Open Hive boxes for offline data
  await Hive.openBox('locations');
  await Hive.openBox('attendance');
  await Hive.openBox('employees');
  await Hive.openBox('geofences');
  await Hive.openBox('settings');

  // Initialize native channel service
  final nativeChannelService = NativeChannelService();
  await nativeChannelService.initialize();

  // Initialize services
  final authService = AuthService();
  final locationService = LocationService(nativeChannelService);
  final attendanceService = AttendanceService();
  final geofenceService = GeofenceService(nativeChannelService);
  final offlineSyncService = OfflineSyncService();

  // Start offline sync service
  offlineSyncService.startSyncMonitoring();

  // Run the application with providers
  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<NativeChannelService>.value(value: nativeChannelService),
        Provider<AuthService>.value(value: authService),
        Provider<LocationService>.value(value: locationService),
        Provider<AttendanceService>.value(value: attendanceService),
        Provider<GeofenceService>.value(value: geofenceService),
        Provider<OfflineSyncService>.value(value: offlineSyncService),

        // BLoC Controllers
        BlocProvider<AuthController>(
          create: (context) => AuthController(authService: authService),
        ),
        BlocProvider<LocationController>(
          create: (context) => LocationController(
            locationService: locationService,
            nativeChannelService: nativeChannelService,
          ),
        ),
        BlocProvider<AttendanceController>(
          create: (context) => AttendanceController(
            attendanceService: attendanceService,
            geofenceService: geofenceService,
          ),
        ),
        BlocProvider<GeofenceController>(
          create: (context) => GeofenceController(
            geofenceService: geofenceService,
          ),
        ),
      ],
      child: const SmartEmployeeApp(),
    ),
  );
}
