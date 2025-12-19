// employee_live_map_page.dart
// Employee self live map with MapTiler (flutter_map)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/geofence_controller.dart';
import '../../models/geofence_model.dart';
import '../../models/location_model.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';

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

class EmployeeLiveMapPage extends StatefulWidget {
  const EmployeeLiveMapPage({super.key});

  @override
  State<EmployeeLiveMapPage> createState() => _EmployeeLiveMapPageState();
}

class _EmployeeLiveMapPageState extends State<EmployeeLiveMapPage> {
  final MapController _mapController = MapController();
  StreamSubscription<LocationModel?>? _locationSub;
  List<CircleMarker> _circles = [];
  Marker? _selfMarker;
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
    _locationSub?.cancel();
    super.dispose();
  }

  void _loadData() {
    final authState = context.read<AuthController>().state;
    if (authState is! AuthAuthenticated) return;

    final companyId = authState.user.companyId;
    final employeeId = authState.user.id;

    context.read<GeofenceController>().add(
          GeofenceLoadAll(companyId: companyId),
        );

    final locationService = context.read<LocationService>();
    _locationSub =
        locationService.streamEmployeeLocation(employeeId).listen((location) {
      if (location == null) return;
      setState(() {
        _selfMarker = Marker(
          point: LatLng(location.latitude, location.longitude),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
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
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ],
          ),
        );
      });
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
              color: Colors.blue.withOpacity(0.08),
              borderColor: Colors.blue,
              borderStrokeWidth: 1.5,
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    if (_selfMarker != null) markers.add(_selfMarker!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Live Map'),
        actions: [
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
                ),
                CircleLayer(circles: _circles),
                MarkerLayer(markers: markers),
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
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'center_me',
                onPressed: () async {
                  final locationService = context.read<LocationService>();
                  final position = await locationService.getCurrentLocation();
                  if (position != null) {
                    _mapController.move(
                      LatLng(position.latitude, position.longitude),
                      16,
                    );
                  }
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Center me'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
