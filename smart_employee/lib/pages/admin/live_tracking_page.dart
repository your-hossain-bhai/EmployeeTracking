// live_tracking_page.dart
// Live Tracking Page
//
// This page displays real-time locations of all employees
// on a MapTiler map using flutter_map. Admin can view employee positions,
// geofence boundaries, and employee status.
// NOTE: Replaced Google Maps with flutter_map + MapTiler

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart'; // Replaced google_maps_flutter
import 'package:latlong2/latlong.dart'; // Replaced google_maps_flutter LatLng

import '../../controllers/auth_controller.dart';
import '../../controllers/geofence_controller.dart';
import '../../services/location_service.dart';
import '../../models/geofence_model.dart';
import '../../widgets/employee_marker_info.dart';

/// MapTiler style options - Enhanced feature for multiple map styles
enum MapStyle {
  streets('Streets', 'streets-v2'),
  satellite('Satellite', 'hybrid'),
  pastel('Pastel', 'pastel'),
  basic('Basic', 'basic-v2'),
  outdoor('Outdoor', 'outdoor-v2');

  final String label;
  final String tileStyle;

  const MapStyle(this.label, this.tileStyle);

  String getUrl(String apiKey) =>
      'https://api.maptiler.com/maps/$tileStyle/{z}/{x}/{y}.png?key=$apiKey';
}

/// Live tracking page for admin
class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  // Replaced GoogleMapController with MapController from flutter_map
  final MapController _mapController = MapController();
  StreamSubscription<List<EmployeeLocation>>? _locationSubscription;

  List<Marker> _markers = []; // Replaced Set<Marker> with List<Marker>
  List<CircleMarker> _circles =
      []; // Replaced Set<Circle> with List<CircleMarker>
  List<EmployeeLocation> _employeeLocations = [];
  EmployeeLocation? _selectedEmployee;

  // MapTiler style options - Enhanced feature
  MapStyle _currentMapStyle = MapStyle.streets;

  // Replaced LatLng with latlong2 LatLng
  static const LatLng _defaultCenter = LatLng(
    37.7749,
    -122.4194,
  ); // San Francisco
  static const String _mapTilerApiKey =
      'a5fFxhWpyDQZZrUYF2ss'; // MapTiler API Key

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose(); // Fixed: Removed unnecessary null-aware operator
    super.dispose();
  }

  void _loadData() {
    final authState = context.read<AuthController>().state;
    if (authState is! AuthAuthenticated) return;

    final companyId = authState.user.companyId;

    // Load geofences
    context.read<GeofenceController>().add(
          GeofenceLoadAll(companyId: companyId),
        );

    // Subscribe to employee locations
    final locationService = context.read<LocationService>();
    _locationSubscription =
        locationService.streamAllEmployeeLocations(companyId).listen(
      _updateEmployeeMarkers,
      onError: (error) {
        print('Error streaming employee locations: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading employees: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  void _updateEmployeeMarkers(List<EmployeeLocation> locations) {
    setState(() {
      _employeeLocations = locations;
      _markers.clear();

      for (final empLoc in locations) {
        if (empLoc.hasLocation) {
          // Replaced Google Maps Marker with flutter_map Marker
          _markers.add(
            Marker(
              point: LatLng(
                empLoc.location!.latitude,
                empLoc.location!.longitude,
              ),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEmployee = empLoc;
                  });
                },
                child: Icon(
                  Icons.location_on,
                  size: 40,
                  color: empLoc.isOnline ? Colors.green : Colors.orange,
                ),
              ),
            ),
          );
        }
      }
    });
  }

  void _updateGeofenceCircles(List<GeofenceModel> geofences) {
    setState(() {
      _circles.clear();
      for (final geofence in geofences) {
        // Replaced Google Maps Circle with flutter_map CircleMarker
        _circles.add(
          CircleMarker(
            point: LatLng(geofence.latitude, geofence.longitude),
            radius: geofence.radius,
            color: Colors.blue.withOpacity(0.1),
            borderColor: Colors.blue,
            borderStrokeWidth: 2,
            useRadiusInMeter: true, // Important: use radius in meters
          ),
        );
      }
    });
  }

  // Replaced CameraUpdate logic with MapController methods
  void _fitMapToBounds() {
    if (_markers.isEmpty) return;

    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final marker in _markers) {
      final pos = marker.point;
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

    // Replaced CameraUpdate with MapController.fitCamera
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: _fitMapToBounds,
          ),
          // Enhanced: Map style selector
          PopupMenuButton<MapStyle>(
            icon: const Icon(Icons.layers),
            tooltip: 'Map Style',
            onSelected: (style) {
              setState(() => _currentMapStyle = style);
            },
            itemBuilder: (context) => MapStyle.values
                .map((style) => PopupMenuItem(
                      value: style,
                      child: Row(
                        children: [
                          Icon(
                            style == _currentMapStyle
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(style.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: BlocListener<GeofenceController, GeofenceState>(
        listener: (context, state) {
          if (state is GeofenceLoaded) {
            _updateGeofenceCircles(state.geofences);
          }
        },
        child: Stack(
          children: [
            // Replaced GoogleMap with flutter_map FlutterMap + MapTiler
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                // Replaced initialCameraPosition with center and zoom
                initialCenter: _defaultCenter,
                initialZoom: 12,
                minZoom: 3,
                maxZoom: 18,
              ),
              children: [
                // MapTiler tile layer - replaces Google Maps tiles
                // Enhanced: Dynamic map style switching
                TileLayer(
                  urlTemplate: _currentMapStyle.getUrl(_mapTilerApiKey),
                  userAgentPackageName: 'com.example.smart_employee',
                  maxZoom: 19,
                ),
                // Circle layer for geofences
                CircleLayer(circles: _circles),
                // Marker layer for employees
                MarkerLayer(markers: _markers),
              ],
            ),

            // Employee List Panel
            Positioned(
              top: 16,
              left: 16,
              child: Card(
                child: Container(
                  width: 200,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Employees',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '(${_employeeLocations.length})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (_employeeLocations.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No employees found.\nMake sure employees are registered with your company.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _employeeLocations.length,
                            itemBuilder: (context, index) {
                              final empLoc = _employeeLocations[index];
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: empLoc.isOnline
                                      ? Colors.green
                                      : Colors.orange,
                                  child: const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  empLoc.employee.displayName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                subtitle: Text(
                                  empLoc.hasLocation
                                      ? (empLoc.isOnline ? 'Online' : 'Offline')
                                      : 'No location data',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        empLoc.hasLocation ? null : Colors.red,
                                  ),
                                ),
                                onTap: () {
                                  if (empLoc.hasLocation) {
                                    // Move map to employee location
                                    _mapController.move(
                                      LatLng(
                                        empLoc.location!.latitude,
                                        empLoc.location!.longitude,
                                      ),
                                      15,
                                    );
                                    setState(() {
                                      _selectedEmployee = empLoc;
                                    });
                                  } else {
                                    // Show message if no location
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${empLoc.employee.displayName} has no location data yet.\nThey need to open the app and share their location.',
                                        ),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Selected Employee Info
            if (_selectedEmployee != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: EmployeeMarkerInfo(
                  employeeLocation: _selectedEmployee!,
                  onClose: () {
                    setState(() {
                      _selectedEmployee = null;
                    });
                  },
                ),
              ),

            // Legend
            Positioned(
              bottom: _selectedEmployee != null ? 140 : 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(Colors.green, 'Online'),
                      const SizedBox(height: 4),
                      _buildLegendItem(Colors.orange, 'Offline'),
                      const SizedBox(height: 4),
                      _buildLegendItem(Colors.blue, 'Geofence'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
