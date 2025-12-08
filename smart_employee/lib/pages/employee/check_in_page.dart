// check_in_page.dart
// Check-In Page
// 
// This page allows employees to check-in/check-out manually.
// It includes location verification, proof upload, and geofence checking.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/geofence_controller.dart';
import '../../models/attendance_model.dart';
import '../../models/geofence_model.dart';
import '../../services/location_service.dart';
import '../../utils/helpers.dart';

/// Check-in page for employees
class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isInsideGeofence = false;
  GeofenceModel? _nearestGeofence;
  File? _proofImage;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load geofences
    final authState = context.read<AuthController>().state;
    if (authState is AuthAuthenticated) {
      context.read<GeofenceController>().add(
            GeofenceLoadAll(companyId: authState.user.companyId),
          );
      
      // Load today's attendance
      context.read<AttendanceController>().add(
            AttendanceGetToday(employeeId: authState.user.id),
          );
    }

    // Get current location
    await _getCurrentLocation();

    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    final locationService = context.read<LocationService>();
    
    final permission = await locationService.checkPermission();
    if (permission == LocationPermission.denied) {
      await locationService.requestPermission();
    }

    final position = await locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentPosition = position;
      });
      _checkGeofence();
    }
  }

  void _checkGeofence() {
    if (_currentPosition == null) return;

    final geofenceState = context.read<GeofenceController>().state;
    if (geofenceState is GeofenceLoaded) {
      for (final geofence in geofenceState.geofences) {
        final isInside = LocationHelpers.isInsideGeofence(
          pointLat: _currentPosition!.latitude,
          pointLon: _currentPosition!.longitude,
          centerLat: geofence.latitude,
          centerLon: geofence.longitude,
          radiusMeters: geofence.radius,
        );

        if (isInside) {
          setState(() {
            _isInsideGeofence = true;
            _nearestGeofence = geofence;
          });
          return;
        }
      }
    }

    setState(() {
      _isInsideGeofence = false;
      _nearestGeofence = null;
    });
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _proofImage = File(picked.path);
      });
    }
  }

  void _handleCheckIn() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location')),
      );
      return;
    }

    final authState = context.read<AuthController>().state;
    if (authState is! AuthAuthenticated) return;

    context.read<AttendanceController>().add(
          AttendanceCheckIn(
            employeeId: authState.user.id,
            companyId: authState.user.companyId,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            geofenceId: _nearestGeofence?.id,
            isInsideGeofence: _isInsideGeofence,
            method: CheckInMethod.manual,
            proofImage: _proofImage,
          ),
        );
  }

  void _handleCheckOut(String attendanceId) {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location')),
      );
      return;
    }

    context.read<AttendanceController>().add(
          AttendanceCheckOut(
            attendanceId: attendanceId,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            isInsideGeofence: _isInsideGeofence,
            proofImage: _proofImage,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In / Out'),
      ),
      body: BlocConsumer<AttendanceController, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceCheckedIn) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully checked in!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is AttendanceCheckedOut) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully checked out!'),
                backgroundColor: Colors.blue,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is AttendanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, attendanceState) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Determine if already checked in
          bool isCheckedIn = false;
          String? attendanceId;
          if (attendanceState is AttendanceTodayLoaded &&
              attendanceState.attendance != null) {
            isCheckedIn = attendanceState.attendance!.isCheckedIn;
            attendanceId = attendanceState.attendance!.id;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Location Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: _currentPosition != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currentPosition != null
                                  ? 'Location acquired'
                                  : 'Getting location...',
                              style: TextStyle(
                                color: _currentPosition != null
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_currentPosition != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                            'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Location'),
                          onPressed: _getCurrentLocation,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Geofence Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isInsideGeofence
                                  ? Icons.verified
                                  : Icons.warning,
                              color: _isInsideGeofence
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isInsideGeofence
                                        ? 'Inside Office Geofence'
                                        : 'Outside Office Geofence',
                                    style: TextStyle(
                                      color: _isInsideGeofence
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_nearestGeofence != null)
                                    Text(
                                      _nearestGeofence!.name,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!_isInsideGeofence) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'You are not inside any designated office area. '
                            'Your check-in will be recorded but may require approval.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Proof Image Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Proof Photo (Optional)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_proofImage != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _proofImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Retake'),
                                  onPressed: _pickImage,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Remove'),
                                  onPressed: () {
                                    setState(() {
                                      _proofImage = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ] else
                          OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                            onPressed: _pickImage,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isCheckedIn ? Colors.red : Colors.green,
                    ),
                    onPressed: attendanceState is AttendanceLoading ||
                            _currentPosition == null
                        ? null
                        : () {
                            if (isCheckedIn && attendanceId != null) {
                              _handleCheckOut(attendanceId);
                            } else {
                              _handleCheckIn();
                            }
                          },
                    child: attendanceState is AttendanceLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isCheckedIn ? Icons.logout : Icons.login,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isCheckedIn ? 'CHECK OUT' : 'CHECK IN',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
