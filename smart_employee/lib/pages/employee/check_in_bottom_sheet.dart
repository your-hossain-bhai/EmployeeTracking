import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/geofence_controller.dart';
import '../../models/attendance_model.dart';
import '../../models/geofence_model.dart';
import '../../services/location_service.dart';
import '../../utils/helpers.dart';

class CheckInBottomSheet extends StatefulWidget {
  final bool isCheckOut;
  final String? attendanceId;

  const CheckInBottomSheet({
    super.key,
    this.isCheckOut = false,
    this.attendanceId,
  });

  @override
  State<CheckInBottomSheet> createState() => _CheckInBottomSheetState();
}

class _CheckInBottomSheetState extends State<CheckInBottomSheet>
    with SingleTickerProviderStateMixin {
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isInsideGeofence = false;
  GeofenceModel? _nearestGeofence;
  File? _proofImage;
  final _imagePicker = ImagePicker();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _actionTriggered = false; // Track if this sheet triggered the action

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final authState = context.read<AuthController>().state;
    if (authState is AuthAuthenticated) {
      context.read<GeofenceController>().add(
        GeofenceLoadAll(companyId: authState.user.companyId),
      );
    }
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
    if (position != null && mounted) {
      setState(() => _currentPosition = position);
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
    if (picked != null && mounted) {
      setState(() => _proofImage = File(picked.path));
    }
  }

  void _handleAction() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location not available')));
      return;
    }

    final authState = context.read<AuthController>().state;
    if (authState is! AuthAuthenticated) return;

    _actionTriggered = true; // Mark that this sheet triggered the action

    if (widget.isCheckOut && widget.attendanceId != null) {
      context.read<AttendanceController>().add(
        AttendanceCheckOut(
          attendanceId: widget.attendanceId!,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          isInsideGeofence: _isInsideGeofence,
          proofImage: _proofImage,
        ),
      );
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return BlocConsumer<AttendanceController, AttendanceState>(
      listener: (context, state) {
        // Only close dialog if this sheet triggered the action
        if (_actionTriggered &&
            (state is AttendanceCheckedIn || state is AttendanceCheckedOut)) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isCheckOut
                    ? '✓ Checked out successfully!'
                    : '✓ Checked in successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (_actionTriggered && state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, attendanceState) {
        final isProcessing = attendanceState is AttendanceLoading;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                )
              else ...[
                // Time Display
                Text(
                  DateFormat.jm().format(now),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMMd().format(now),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // Animated Action Circle
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.isCheckOut
                            ? [Colors.deepOrange, Colors.red]
                            : [cs.primary, cs.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isCheckOut ? Colors.red : cs.primary)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isCheckOut
                          ? Icons.logout_rounded
                          : Icons.login_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Status Chips
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    Chip(
                      avatar: Icon(
                        _currentPosition != null
                            ? Icons.location_on
                            : Icons.location_off,
                        size: 16,
                        color: _currentPosition != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      label: Text(
                        _currentPosition != null
                            ? 'Location acquired'
                            : 'No location',
                      ),
                    ),
                    Chip(
                      avatar: Icon(
                        _isInsideGeofence
                            ? Icons.verified
                            : Icons.warning_amber,
                        size: 16,
                        color: _isInsideGeofence ? Colors.green : Colors.orange,
                      ),
                      label: Text(
                        _isInsideGeofence ? 'Inside office' : 'Outside office',
                      ),
                    ),
                  ],
                ),
                if (_nearestGeofence != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _nearestGeofence!.name,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 24),

                // Photo Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (_proofImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _proofImage!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Retake'),
                                onPressed: _pickImage,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  setState(() => _proofImage = null),
                            ),
                          ],
                        ),
                      ] else
                        OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Add photo (optional)'),
                          onPressed: _pickImage,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isProcessing || _currentPosition == null
                          ? null
                          : _handleAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isCheckOut
                            ? Colors.red
                            : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.isCheckOut ? 'CHECK OUT' : 'CHECK IN',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
