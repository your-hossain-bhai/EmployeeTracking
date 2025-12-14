// live_tracking_page.dart
// Live Tracking Page - Google Maps Version

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/geofence_controller.dart';
import '../../services/location_service.dart';
import '../../models/geofence_model.dart';
import '../../widgets/employee_marker_info.dart';

/// Google Maps style options
enum MapStyle {
  normal('Normal', MapType.normal),
  satellite('Satellite', MapType.satellite),
  terrain('Terrain', MapType.terrain),
  hybrid('Hybrid', MapType.hybrid);

  final String label;
  final MapType mapType;

  const MapStyle(this.label, this.mapType);
}

/// Live tracking page for admin
class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  GoogleMapController? _mapController;
  StreamSubscription<List<EmployeeLocation>>? _locationSubscription;

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  List<EmployeeLocation> _employeeLocations = [];
  EmployeeLocation? _selectedEmployee;

  MapStyle _currentMapStyle = MapStyle.normal;

  // Default center (Bangladesh - IIUC area)
  static const LatLng _defaultCenter = LatLng(22.4994, 91.7773);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _loadData() {
    final authState = context.read<AuthController>().state;
    if (authState is! AuthAuthenticated) return;

    final companyId = authState.user.companyId;

    context.read<GeofenceController>().add(
          GeofenceLoadAll(companyId: companyId),
        );

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
          _markers.add(
            Marker(
              markerId: MarkerId(empLoc.employee.id),
              position: LatLng(
                empLoc.location!.latitude,
                empLoc.location!.longitude,
              ),
              infoWindow: InfoWindow(
                title: empLoc.employee.displayName,
                snippet: empLoc.isOnline ? 'Online' : 'Offline',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                empLoc.isOnline
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueOrange,
              ),
              onTap: () {
                setState(() {
                  _selectedEmployee = empLoc;
                });
              },
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
        _circles.add(
          Circle(
            circleId: CircleId(geofence.id),
            center: LatLng(geofence.latitude, geofence.longitude),
            radius: geofence.radius,
            fillColor: Colors.blue.withOpacity(0.1),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        );
      }
    });
  }

  void _fitMapToBounds() {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final marker in _markers) {
      final pos = marker.position;
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
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
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _defaultCenter,
                zoom: 12,
              ),
              mapType: _currentMapStyle.mapType,
              markers: _markers,
              circles: _circles,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
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
                            'No employees found.\nMake sure employees are registered.',
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
                                  child: const Icon(Icons.person,
                                      size: 14, color: Colors.white),
                                ),
                                title: Text(
                                  empLoc.employee.displayName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                subtitle: Text(
                                  empLoc.hasLocation
                                      ? (empLoc.isOnline ? 'Online' : 'Offline')
                                      : 'No location',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        empLoc.hasLocation ? null : Colors.red,
                                  ),
                                ),
                                onTap: () {
                                  if (empLoc.hasLocation) {
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                        LatLng(
                                          empLoc.location!.latitude,
                                          empLoc.location!.longitude,
                                        ),
                                        15,
                                      ),
                                    );
                                    setState(() {
                                      _selectedEmployee = empLoc;
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${empLoc.employee.displayName} has no location data.',
                                        ),
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
            if (_selectedEmployee != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: EmployeeMarkerInfo(
                  employeeLocation: _selectedEmployee!,
                  onClose: () => setState(() => _selectedEmployee = null),
                ),
              ),
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
            Positioned(
              bottom: _selectedEmployee != null ? 140 : 16,
              left: 16,
              child: FloatingActionButton.small(
                heroTag: 'myLocation',
                onPressed: () async {
                  final locationService = context.read<LocationService>();
                  final position = await locationService.getCurrentLocation();
                  if (position != null && _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(position.latitude, position.longitude),
                        15,
                      ),
                    );
                  }
                },
                child: const Icon(Icons.my_location),
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
