# This README would normally document whatever steps are necessary to get your iOS app running

## iOS Background Location Limitations

Unlike Android, iOS has strict limitations on background location tracking:

1. **Background Location Updates**: iOS allows continuous background location updates, but this drains battery significantly and requires extra App Store review justification.

2. **Significant Location Change**: This is more battery-efficient but only triggers updates when the user moves approximately 500 meters.

3. **Geofencing**: iOS supports up to 20 monitored geofences per app. This is handled by the system and is efficient.

## Required Permissions

The following keys must be in `Info.plist`:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`

## Background Modes

Enable these in Xcode under "Signing & Capabilities":
- Location updates
- Background fetch
- Remote notifications (for Firebase Cloud Messaging)

## Native Implementation Note

Unlike Android where we implemented a native Kotlin foreground service, iOS background location is primarily handled through Flutter plugins (`geolocator`) with the proper plist configurations. A native Swift implementation for continuous background tracking would require:
1. Creating a `LocationManager` class
2. Implementing `CLLocationManagerDelegate`
3. Calling `startUpdatingLocation()` with `allowsBackgroundLocationUpdates = true`

However, for most use cases, the Flutter plugin approach combined with significant location change monitoring provides the best balance of functionality and battery life.
