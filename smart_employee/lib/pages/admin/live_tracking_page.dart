// live_tracking_page.dart
// Live Tracking Page - MapTiler (flutter_map)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/geofence_controller.dart';
import '../../models/geofence_model.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';
import '../../widgets/employee_marker_info.dart';

/// Map styles backed by MapTiler
enum MapStyle {
  streets('Streets', AppConstants.mapTilerStreetsUrl),
  satellite('Satellite', AppConstants.mapTilerSatelliteUrl),
  terrain('Terrain', AppConstants.mapTilerTerrainUrl),
  hybrid('Hybrid', AppConstants.mapTilerHybridUrl);

  final String label;
  final String tileUrl;

  const MapStyle(this.label, this.tileUrl);
}

/// Live tracking page for admin
class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final MapController _mapController = MapController();
  StreamSubscription<List<EmployeeLocation>>? _locationSubscription;

  List<Marker> _markers = [];
  List<CircleMarker> _circles = [];
  List<EmployeeLocation> _employeeLocations = [];
  EmployeeLocation? _selectedEmployee;

  MapStyle _currentMapStyle = MapStyle.streets;

  // Default center (Bangladesh - IIUC area)
  static final LatLng _defaultCenter = LatLng(22.4994, 91.7773);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
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
        // Avoid crashing UI on stream errors
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
      _markers = locations.where((empLoc) => empLoc.hasLocation).map((empLoc) {
        final loc = empLoc.location!;
        final isOnline = empLoc.isOnline;
        return Marker(
          point: LatLng(loc.latitude, loc.longitude),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => setState(() => _selectedEmployee = empLoc),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    empLoc.employee.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList();
    });
  }

  void _updateGeofenceCircles(List<GeofenceModel> geofences) {
    setState(() {
      _circles = geofences
          .map(
            (geofence) => CircleMarker(
              point: LatLng(geofence.latitude, geofence.longitude),
              radius: geofence.radius,
              useRadiusInMeter: true,
              color: Colors.blue.withOpacity(0.1),
              borderColor: Colors.blue,
              borderStrokeWidth: 2,
            ),
          )
          .toList();
    });
  }

  void _fitMapToBounds() {
    if (_markers.isEmpty) return;

    final bounds = LatLngBounds(_markers.first.point, _markers.first.point);
    for (final marker in _markers.skip(1)) {
      bounds.extend(marker.point);
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
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
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 12,
                minZoom: AppConstants.minMapZoom,
                maxZoom: AppConstants.maxMapZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: _currentMapStyle.tileUrl,
                  userAgentPackageName: AppConstants.mapTilerUserAgent,
                  minZoom: AppConstants.minMapZoom,
                  maxZoom: AppConstants.maxMapZoom,
                  retinaMode: false,
                ),
                CircleLayer(circles: _circles),
                MarkerLayer(markers: _markers),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© MapTiler © OpenStreetMap contributors',
                      prependCopyright: true,
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Card(
                child: Container(
                  width: 220,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
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
                                    final loc = empLoc.location!;
                                    _mapController.move(
                                      LatLng(loc.latitude, loc.longitude),
                                      15,
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
                  if (position != null) {
                    _mapController.move(
                      LatLng(position.latitude, position.longitude),
                      15,
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
