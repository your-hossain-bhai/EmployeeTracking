# Smart Employee - Employee Tracking & Management Solution

A comprehensive Flutter application for smart employee tracking and management with real-time location tracking, geofencing, and automated attendance features.

## 📱 Features

### Admin Portal
- **Dashboard**: Overview of employee statistics and attendance
- **Live Tracking**: Real-time Google Maps view of all employee locations
- **Employee Management**: Add, edit, and manage employees
- **Geofence Management**: Create and manage office geofence zones
- **Attendance Reports**: View and export attendance data

### Employee Portal
- **Dashboard**: Today's attendance status and quick actions
- **Check-In/Out**: Manual check-in with location verification
- **Attendance History**: View personal attendance records and statistics
- **Profile Management**: Update profile and account settings

### Core Features
- **Background Location Tracking**: Native Android foreground service
- **Geofencing**: Automatic attendance via geofence enter/exit
- **Offline Support**: Local storage with automatic sync
- **Push Notifications**: Attendance reminders and geofence alerts

## 🏗️ Architecture

```
lib/
├── main.dart              # App entry point
├── app.dart               # Main app widget
├── routes.dart            # Navigation routes
├── config/
│   └── firebase_options.dart(.template)
├── models/                # Data models
│   ├── user_model.dart
│   ├── location_model.dart
│   ├── attendance_model.dart
│   ├── geofence_model.dart
│   └── company_model.dart
├── services/              # Business logic & data layer
│   ├── native_channel_service.dart
│   ├── background_location_service.dart
│   ├── offline_sync_service.dart
│   ├── auth_service.dart
│   ├── location_service.dart
│   ├── attendance_service.dart
│   └── geofence_service.dart
├── controllers/           # BLoC controllers
│   ├── auth_controller.dart
│   ├── location_controller.dart
│   ├── attendance_controller.dart
│   └── geofence_controller.dart
├── pages/                 # UI screens
│   ├── auth/
│   ├── admin/
│   └── employee/
├── widgets/               # Reusable widgets
└── utils/                 # Utilities & helpers
    ├── constants.dart
    ├── extensions.dart
    └── helpers.dart
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Android Studio / VS Code
- Firebase project
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ShuvroLabs/Employee-Manager.git
   cd Employee-Manager/smart_employee
   ```

2. **Regenerate Flutter project scaffolding** (IMPORTANT - Required for first-time setup)
   ```bash
   # This regenerates the missing Flutter infrastructure files (android gradle wrapper, etc.)
   flutter create . --org com.example --project-name smart_employee
   ```
   
   This command will:
   - Generate missing Android gradle files (`gradlew`, `gradle-wrapper.jar`, etc.)
   - Create/update local.properties with your Flutter SDK path
   - Generate iOS xcodeproj files
   - Preserve your existing Dart code and custom native implementations

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Firebase**
   
   Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
   
   Configure your Firebase project:
   ```bash
   flutterfire configure
   ```
   
   This will replace the placeholder `lib/config/firebase_options.dart` with your project's actual configuration.
   
   > **Note:** The included `firebase_options.dart` contains placeholder values to allow compilation. The app won't connect to Firebase until you run `flutterfire configure` to generate the real configuration.

5. **MapTiler Configuration (Already Configured)**
   
   The app uses MapTiler for maps instead of Google Maps. The MapTiler API key is already configured in the code:
   - **API Key**: `a5fFxhWpyDQZZrUYF2ss`
   - **Map Style**: Streets v2
   - No additional setup required!
   
   > **Note:** Google Maps has been completely replaced with MapTiler using `flutter_map`. No Google Maps API key is needed.

6. **Register Android SHA1**
   
   Get your SHA1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   
   Add the SHA1 to your Firebase project settings.

7. **Run the app**
   ```bash
   flutter run
   ```

## ⚙️ Configuration

### Android Permissions

The app requires the following permissions (already configured in AndroidManifest.xml):

- `ACCESS_FINE_LOCATION` - GPS location
- `ACCESS_COARSE_LOCATION` - Network location
- `ACCESS_BACKGROUND_LOCATION` - Background tracking
- `FOREGROUND_SERVICE` - Foreground service
- `POST_NOTIFICATIONS` - Push notifications (Android 13+)

### Battery Optimization

For reliable background location tracking, users should:

1. Disable battery optimization for the app
2. Allow "All the time" location access
3. Lock the app in recent apps (manufacturer specific)

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId || 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Companies collection
    match /companies/{companyId} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Locations collection
    match /locations/{locationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                      request.resource.data.employeeId == request.auth.uid;
      allow update, delete: if false;
    }
    
    // Attendance collection
    match /attendance/{attendanceId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.employeeId ||
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Geofences collection
    match /geofences/{geofenceId} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## 📊 Firestore Schema

### Users Collection
```json
{
  "email": "string",
  "displayName": "string",
  "photoUrl": "string?",
  "role": "admin | employee",
  "companyId": "string",
  "departmentId": "string?",
  "phoneNumber": "string?",
  "isActive": "boolean",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Locations Collection
```json
{
  "employeeId": "string",
  "latitude": "number",
  "longitude": "number",
  "accuracy": "number",
  "altitude": "number?",
  "speed": "number?",
  "heading": "number?",
  "timestamp": "timestamp",
  "isMocked": "boolean"
}
```

### Attendance Collection
```json
{
  "employeeId": "string",
  "companyId": "string",
  "date": "timestamp",
  "checkInTime": "timestamp?",
  "checkOutTime": "timestamp?",
  "status": "checkedIn | checkedOut | absent | halfDay",
  "checkInMethod": "automatic | manual | qrCode",
  "checkInLatitude": "number?",
  "checkInLongitude": "number?",
  "geofenceId": "string?",
  "isInsideGeofence": "boolean",
  "isGeofenceVerified": "boolean",
  "checkInProofUrl": "string?",
  "isManuallyOverridden": "boolean",
  "overriddenBy": "string?",
  "overrideReason": "string?"
}
```

### Geofences Collection
```json
{
  "companyId": "string",
  "name": "string",
  "description": "string?",
  "latitude": "number",
  "longitude": "number",
  "radius": "number",
  "type": "office | branch | warehouse | clientSite | custom",
  "isActive": "boolean",
  "autoCheckIn": "boolean",
  "autoCheckOut": "boolean",
  "workStartTime": "string?",
  "workEndTime": "string?"
}
```

## 🔧 Demo Data

To populate Firestore with demo data:

```bash
cd tools
dart run seed_demo.dart
```

This creates sample data including:
- 1 company
- 1 admin user
- 3 employee users
- 1 geofence (office)
- Sample attendance records
- Sample location logs

See `seed_data/_summary.json` for credentials.

## 📱 iOS Configuration

iOS has limitations for continuous background location tracking. For iOS support:

1. Add to `ios/Runner/Info.plist`:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need your location to track attendance</string>
   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>We need background location for automatic check-in</string>
   <key>UIBackgroundModes</key>
   <array>
       <string>location</string>
       <string>fetch</string>
       <string>remote-notification</string>
   </array>
   ```

2. Note: iOS background location is limited to significant location changes. For continuous tracking similar to Android, consider using significant location changes or region monitoring.

## 🔒 Privacy & Data Retention

- Location data is retained for **90 days** by default
- Attendance records are retained for **1 year**
- Users can request data deletion through profile settings
- All data is encrypted in transit (HTTPS/TLS)
- Firestore security rules enforce access control

## ⚡ Performance & Battery

### Battery Optimization Tips

1. **Update Interval**: Default 30 seconds, configurable per company
2. **Accuracy**: Uses PRIORITY_BALANCED_POWER_ACCURACY when sufficient
3. **Geofencing**: Uses native GeofencingClient for efficient monitoring
4. **Batch Uploads**: Locations are batched before upload to reduce network calls

### Recommended Settings

| Use Case | Interval | Accuracy |
|----------|----------|----------|
| Field workers | 30s | High |
| Office workers | 60s | Balanced |
| Delivery | 15s | High |

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

## 📦 Building

```bash
# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release

# Build iOS (on macOS)
flutter build ios --release
```

## 🛠️ Cloud Functions (Pseudocode)

For automated notifications, deploy these Cloud Functions:

```javascript
// functions/index.js
exports.onGeofenceEnter = functions.firestore
  .document('attendance/{attendanceId}')
  .onCreate(async (snap, context) => {
    const attendance = snap.data();
    // Send notification to admin
    // Log geofence entry
  });

exports.dailyAttendanceReminder = functions.pubsub
  .schedule('0 9 * * 1-5')
  .timeZone('America/Los_Angeles')
  .onRun(async (context) => {
    // Send check-in reminders to employees
  });

exports.cleanupOldLocations = functions.pubsub
  .schedule('0 2 * * *')
  .onRun(async (context) => {
    // Delete location data older than retention period
  });
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Support

For support, please contact:
- Email: muhammadhossain.27.2001@gmail.com
- GitHub Issues: [Create Issue](https://github.com/ShuvroLabs/Employee-Manager/issues)
