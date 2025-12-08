# MapTiler Quick Reference Guide

## 🚀 Quick Start

### Run the App
```bash
cd g:\Attendance\smart_employee
flutter pub get
flutter run
```

### MapTiler API Key
```
a5fFxhWpyDQZZrUYF2ss
```

---

## 📍 Map Screens

### 1. Live Tracking (`lib/pages/admin/live_tracking_page.dart`)
- View real-time employee locations
- Green markers = Online employees
- Orange markers = Offline employees  
- Blue circles = Geofences
- **NEW**: Layer icon to switch map styles

### 2. Geofence Management (`lib/pages/admin/geofence_management_page.dart`)
- View and manage geofences
- Long-press map to add geofence
- Tap marker for details
- **NEW**: Layer icon to switch map styles

---

## 🎨 Map Styles

Available via Layer icon (🗂️) in AppBar:

1. **Streets** (Default) - Street map view
2. **Satellite** - Aerial/satellite imagery
3. **Pastel** - Soft color palette
4. **Basic** - Minimalist style
5. **Outdoor** - Terrain and topography

---

## 🔧 Configuration Files

### Dependencies (`pubspec.yaml`)
```yaml
flutter_map: ^7.0.0      # Map rendering
latlong2: ^0.9.0         # Coordinates
geolocator: ^13.0.2      # Location
```

### MapTiler Setup (Already configured)
- API Key: In code
- Styles: 5 available
- Location: `lib/pages/admin/live_tracking_page.dart:47`
- Location: `lib/pages/admin/geofence_management_page.dart:53`

---

## 🗺️ Code Examples

### Switch Map Style
```dart
setState(() => _currentMapStyle = MapStyle.satellite);
```

### Move Camera to Location
```dart
_mapController.move(LatLng(latitude, longitude), zoomLevel);
```

### Fit All Markers
```dart
_mapController.fitCamera(
  CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)),
);
```

### Add Marker
```dart
_markers.add(
  Marker(
    point: LatLng(lat, lng),
    width: 40,
    height: 40,
    child: Icon(Icons.location_on, color: Colors.green),
  ),
);
```

### Add Geofence Circle
```dart
_circles.add(
  CircleMarker(
    point: LatLng(lat, lng),
    radius: radiusInMeters,
    color: Colors.blue.withOpacity(0.1),
    borderColor: Colors.blue,
    borderStrokeWidth: 2,
    useRadiusInMeter: true,
  ),
);
```

---

## 🐛 Common Issues

### Map not loading?
- Check internet connection
- Verify API key: `a5fFxhWpyDQZZrUYF2ss`
- Clear app data and restart

### Markers not showing?
- Ensure Firestore has location data
- Check employee `isActive: true`
- Verify location timestamp is recent

### Circles wrong size?
- Confirm `useRadiusInMeter: true`
- Check radius value is in meters
- Verify coordinate accuracy

---

## 📱 Testing Locations

Default Center (San Francisco):
```dart
LatLng(37.7749, -122.4194)
```

Test with these coordinates:
- New York: `LatLng(40.7128, -74.0060)`
- London: `LatLng(51.5074, -0.1278)`
- Tokyo: `LatLng(35.6762, 139.6503)`

---

## 🎯 Key Features

### Real-Time Tracking
- Updates every 5 seconds
- Online/offline status
- Automatic marker color
- Employee info on tap

### Geofencing
- Visual circles on map
- Auto check-in/out
- Multiple geofence types
- Long-press to add

### Background Tracking
- Foreground service (Android)
- Persistent notification
- Battery optimized
- Survives app closure

---

## 📚 Documentation Links

- **flutter_map**: https://docs.fleaflet.dev/
- **MapTiler**: https://docs.maptiler.com/
- **Full Migration Guide**: See `GOOGLE_MAPS_TO_MAPTILER_COMPLETE.md`
- **Setup Instructions**: See `README.md`

---

## ✅ Migration Status

**Status**: ✅ COMPLETE  
**Google Maps**: 100% Removed  
**MapTiler**: Fully Integrated  
**Compilation**: ✅ Success  
**Ready for**: Production

---

*Quick Reference v1.0 | December 6, 2025*
