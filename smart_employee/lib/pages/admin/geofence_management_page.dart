// geofence_management_page.dart
// Geofence Management Page
//
// This page allows administrators to manage geofences.
// Features include adding, editing, and removing geofences,
// as well as viewing them on a map.
// NOTE: Replaced Google Maps with flutter_map + MapTiler

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart'; // Replaced google_maps_flutter
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart'; // Replaced google_maps_flutter LatLng
import 'package:permission_handler/permission_handler.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/geofence_controller.dart';
import '../../models/geofence_model.dart';

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

/// Geofence management page for admin
class GeofenceManagementPage extends StatefulWidget {
  const GeofenceManagementPage({super.key});

  @override
  State<GeofenceManagementPage> createState() => _GeofenceManagementPageState();
}

class _GeofenceManagementPageState extends State<GeofenceManagementPage> {
  // Replaced GoogleMapController with MapController from flutter_map
  final MapController _mapController = MapController();
  List<CircleMarker> _circles = []; // Replaced Set<Circle>
  List<Marker> _markers = []; // Replaced Set<Marker>

  // MapTiler style options - Enhanced feature
  MapStyle _currentMapStyle = MapStyle.streets;

  // Replaced LatLng with latlong2 LatLng
  static const LatLng _defaultCenter = LatLng(37.7749, -122.4194);
  static const String _mapTilerApiKey =
      'a5fFxhWpyDQZZrUYF2ss'; // MapTiler API Key

  @override
  void initState() {
    super.initState();
    _loadGeofences();
  }

  void _loadGeofences() {
    final authState = context.read<AuthController>().state;
    if (authState is AuthAuthenticated) {
      context.read<GeofenceController>().add(
            GeofenceLoadAll(companyId: authState.user.companyId),
          );
    }
  }

  void _updateMapElements(List<GeofenceModel> geofences) {
    _circles.clear();
    _markers.clear();

    for (final geofence in geofences) {
      // Replaced Google Maps Circle with flutter_map CircleMarker
      _circles.add(
        CircleMarker(
          point: LatLng(geofence.latitude, geofence.longitude),
          radius: geofence.radius,
          color: _getGeofenceColor(geofence.type).withOpacity(0.2),
          borderColor: _getGeofenceColor(geofence.type),
          borderStrokeWidth: 2,
          useRadiusInMeter: true, // Important: use radius in meters
        ),
      );

      // Replaced Google Maps Marker with flutter_map Marker
      _markers.add(
        Marker(
          point: LatLng(geofence.latitude, geofence.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showGeofenceDetails(geofence),
            child: Icon(
              _getGeofenceIcon(geofence.type),
              size: 40,
              color: _getGeofenceColor(geofence.type),
            ),
          ),
        ),
      );
    }
  }

  Color _getGeofenceColor(GeofenceType type) {
    switch (type) {
      case GeofenceType.office:
        return Colors.blue;
      case GeofenceType.branch:
        return Colors.green;
      case GeofenceType.warehouse:
        return Colors.orange;
      case GeofenceType.clientSite:
        return Colors.purple;
      case GeofenceType.custom:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: _showAddGeofenceDialog,
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
      body: BlocConsumer<GeofenceController, GeofenceState>(
        listener: (context, state) {
          if (state is GeofenceLoaded) {
            setState(() {
              _updateMapElements(state.geofences);
            });
          } else if (state is GeofenceAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Geofence added successfully')),
            );
          } else if (state is GeofenceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Replaced GoogleMap with flutter_map FlutterMap + MapTiler
              Expanded(
                flex: 2,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    // Replaced initialCameraPosition with center and zoom
                    initialCenter: _defaultCenter,
                    initialZoom: 12,
                    minZoom: 3,
                    maxZoom: 18,
                    onLongPress: (tapPosition, point) {
                      _showAddGeofenceDialogAtPosition(point);
                    },
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
                    // Marker layer for geofences
                    MarkerLayer(markers: _markers),
                  ],
                ),
              ),

              // Geofence List
              Expanded(
                child: state is GeofenceLoaded
                    ? ListView.builder(
                        itemCount: state.geofences.length,
                        itemBuilder: (context, index) {
                          final geofence = state.geofences[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getGeofenceColor(
                                geofence.type,
                              ).withOpacity(0.2),
                              child: Icon(
                                _getGeofenceIcon(geofence.type),
                                color: _getGeofenceColor(geofence.type),
                              ),
                            ),
                            title: Text(geofence.name),
                            subtitle: Text(
                              '${geofence.radius}m • ${geofence.type.name}',
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: ListTile(
                                    leading: Icon(Icons.visibility),
                                    title: Text('View on Map'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Edit'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'view':
                                    // Replaced CameraUpdate with MapController.move
                                    _mapController.move(
                                      LatLng(
                                        geofence.latitude,
                                        geofence.longitude,
                                      ),
                                      16,
                                    );
                                    break;
                                  case 'edit':
                                    _showEditGeofenceDialog(geofence);
                                    break;
                                  case 'delete':
                                    _confirmDeleteGeofence(geofence);
                                    break;
                                }
                              },
                            ),
                            onTap: () => _showGeofenceDetails(geofence),
                          );
                        },
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getGeofenceIcon(GeofenceType type) {
    switch (type) {
      case GeofenceType.office:
        return Icons.business;
      case GeofenceType.branch:
        return Icons.store;
      case GeofenceType.warehouse:
        return Icons.warehouse;
      case GeofenceType.clientSite:
        return Icons.location_city;
      case GeofenceType.custom:
        return Icons.location_on;
    }
  }

  void _showAddGeofenceDialog() {
    _showAddGeofenceDialogAtPosition(null);
  }

  Future<bool> _checkAndRequestBackgroundLocationPermission() async {
    // First check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location services'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    // Check fine location permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for geofencing'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location permission in app settings'),
            backgroundColor: Colors.red,
          ),
        );
        await Geolocator.openAppSettings();
      }
      return false;
    }

    // Check background location permission (required for geofencing)
    final bgStatus = await Permission.locationAlways.status;
    if (!bgStatus.isGranted) {
      // Show explanation dialog
      if (mounted) {
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Background Location Required'),
            content: const Text(
              'Geofencing requires "Allow all the time" location permission to detect when employees enter or exit office areas.\n\n'
              'Please select "Allow all the time" on the next screen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );

        if (shouldRequest == true) {
          final result = await Permission.locationAlways.request();
          if (!result.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Background location permission is required for geofencing'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
        } else {
          return false;
        }
      }
    }

    return true;
  }

  void _showAddGeofenceDialogAtPosition(LatLng? position) async {
    // Check permissions first
    final hasPermission = await _checkAndRequestBackgroundLocationPermission();
    if (!hasPermission) return;
    final nameController = TextEditingController();
    final latController = TextEditingController(
      text: position?.latitude.toString() ?? '',
    );
    final lngController = TextEditingController(
      text: position?.longitude.toString() ?? '',
    );
    final radiusController = TextEditingController(text: '100');
    GeofenceType selectedType = GeofenceType.office;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Geofence'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GeofenceType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: GeofenceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value ?? GeofenceType.office;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: lngController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: radiusController,
                  decoration: const InputDecoration(
                    labelText: 'Radius (meters)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final authState = context.read<AuthController>().state;
                if (authState is! AuthAuthenticated) return;

                context.read<GeofenceController>().add(
                      GeofenceAdd(
                        companyId: authState.user.companyId,
                        name: nameController.text.trim(),
                        latitude: double.tryParse(latController.text) ?? 0,
                        longitude: double.tryParse(lngController.text) ?? 0,
                        radius: double.tryParse(radiusController.text) ?? 100,
                        type: selectedType,
                        createdBy: authState.user.id,
                      ),
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGeofenceDetails(GeofenceModel geofence) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              geofence.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Type', geofence.type.name),
            _buildDetailRow('Radius', '${geofence.radius} meters'),
            _buildDetailRow(
              'Location',
              '${geofence.latitude.toStringAsFixed(6)}, ${geofence.longitude.toStringAsFixed(6)}',
            ),
            _buildDetailRow(
              'Auto Check-in',
              geofence.autoCheckIn ? 'Enabled' : 'Disabled',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showEditGeofenceDialog(geofence);
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Replaced CameraUpdate with MapController.move
                      _mapController.move(
                        LatLng(geofence.latitude, geofence.longitude),
                        16,
                      );
                    },
                    child: const Text('View on Map'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }

  void _showEditGeofenceDialog(GeofenceModel geofence) {
    final nameController = TextEditingController(text: geofence.name);
    final radiusController = TextEditingController(
      text: geofence.radius.toString(),
    );
    GeofenceType selectedType = geofence.type;
    bool autoCheckIn = geofence.autoCheckIn;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Geofence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GeofenceType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: GeofenceType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.name));
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedType = value ?? GeofenceType.office;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(labelText: 'Radius (meters)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Auto Check-in'),
                value: autoCheckIn,
                onChanged: (value) {
                  setDialogState(() {
                    autoCheckIn = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updated = geofence.copyWith(
                  name: nameController.text.trim(),
                  radius: double.tryParse(radiusController.text) ?? 100,
                  type: selectedType,
                  autoCheckIn: autoCheckIn,
                );
                context.read<GeofenceController>().add(
                      GeofenceUpdate(geofence: updated),
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGeofence(GeofenceModel geofence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Geofence'),
        content: Text('Are you sure you want to delete "${geofence.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<GeofenceController>().add(
                    GeofenceRemove(geofenceId: geofence.id),
                  );
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
