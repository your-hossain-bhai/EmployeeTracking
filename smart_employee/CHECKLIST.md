# Smart Employee Setup Checklist

This checklist contains manual steps required to fully configure the Smart Employee application.

## ✅ Pre-Setup Requirements

- [ ] Flutter SDK installed (3.0.0 or higher)
- [ ] Android Studio / VS Code with Flutter extensions
- [ ] Google Cloud Console account
- [ ] Firebase account

## 🔧 Initial Project Setup (IMPORTANT - Do this first!)

### Regenerate Flutter Scaffolding
- [ ] Navigate to project: `cd Employee-Manager/smart_employee`
- [ ] Run: `flutter create . --org com.example --project-name smart_employee`
- [ ] This generates missing Android/iOS files while preserving existing code
- [ ] Run: `flutter pub get`

> **Note:** This step is required because the repository contains custom source code without Flutter's generated infrastructure files (like gradle wrapper, xcodeproj, etc.). Running `flutter create .` regenerates these while preserving your Dart code and native implementations.

## 🔥 Firebase Setup

### Project Creation
- [ ] Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- [ ] Enable Google Analytics (optional but recommended)

### Authentication
- [ ] Enable Email/Password authentication in Firebase Console
- [ ] (Optional) Enable Google Sign-In
- [ ] (Optional) Enable Phone authentication

### Firestore Database
- [ ] Create Firestore database in production mode
- [ ] Deploy security rules (see README.md)
- [ ] Create indexes for complex queries

### Firebase Storage
- [ ] Enable Firebase Storage
- [ ] Set storage rules for attendance proofs

### Cloud Messaging (FCM)
- [ ] Enable Cloud Messaging
- [ ] Generate server key for notifications
- [ ] (Optional) Set up notification channels

## 📱 Android Configuration

### SHA1 Registration
- [ ] Generate debug SHA1: `cd android && ./gradlew signingReport`
- [ ] Generate release SHA1 (if building for release)
- [ ] Add SHA1 fingerprints to Firebase project settings

### Google Maps API
- [ ] Enable Maps SDK for Android in Google Cloud Console
- [ ] Create API key with Android app restrictions
- [ ] Add API key to `AndroidManifest.xml`

### FlutterFire Configuration
- [ ] Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
- [ ] Run: `flutterfire configure`
- [ ] Verify `lib/config/firebase_options.dart` is generated
- [ ] Download `google-services.json` and place in `android/app/`

## 🍎 iOS Configuration (Optional)

### Xcode Setup
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Update Bundle Identifier to match Firebase
- [ ] Add `GoogleService-Info.plist` to Runner target

### Capabilities
- [ ] Enable Background Modes (Location updates)
- [ ] Enable Push Notifications
- [ ] Configure signing and provisioning profiles

### Info.plist
- [ ] Add location usage descriptions
- [ ] Add background modes array

## 🗄️ Demo Data Setup

### Running the Seed Script
- [ ] Navigate to: `cd smart_employee/tools`
- [ ] Run: `dart run seed_demo.dart`
- [ ] Check `seed_data/` folder for generated JSON files

### Importing to Firebase
- [ ] Create Firebase Auth users with demo credentials:
  - Admin: admin@democorp.com / Demo123!
  - Employee 1: john@democorp.com / Demo123!
  - Employee 2: sarah@democorp.com / Demo123!
  - Employee 3: michael@democorp.com / Demo123!
- [ ] Import Firestore collections from JSON files
- [ ] Verify data in Firebase Console

## 🔐 Permissions Setup (First Run)

### Android Permissions
- [ ] Grant "Allow all the time" location permission
- [ ] Grant notification permission (Android 13+)
- [ ] Disable battery optimization for the app
- [ ] (Optional) Allow camera permission for proof photos

### Device Settings
- [ ] Enable GPS/Location services
- [ ] Connect to internet (Wi-Fi or mobile data)

## 🧪 Verification Steps

### Basic Functionality
- [ ] App launches without errors
- [ ] Login works with demo credentials
- [ ] Admin dashboard loads correctly
- [ ] Employee dashboard loads correctly

### Location Features
- [ ] Location permission granted
- [ ] Current location displayed on map
- [ ] Background tracking starts without errors
- [ ] Notification appears when tracking

### Attendance Features
- [ ] Check-in works (manual)
- [ ] Check-out works
- [ ] Attendance history loads
- [ ] Geofence detection works (if inside geofence)

### Admin Features
- [ ] Employee list loads
- [ ] Live tracking map works
- [ ] Geofence management works
- [ ] Attendance reports load

## 📦 Build & Release

### Debug Build
- [ ] `flutter run` works without errors
- [ ] App installs and runs on device/emulator

### Release Build
- [ ] Generate keystore for signing
- [ ] Configure `key.properties`
- [ ] `flutter build apk --release` succeeds
- [ ] APK installs and runs correctly

## 🚀 Deployment (Optional)

### Firebase Hosting (for web)
- [ ] `firebase init hosting`
- [ ] `flutter build web`
- [ ] `firebase deploy --only hosting`

### App Distribution
- [ ] Set up Firebase App Distribution
- [ ] Add testers
- [ ] Upload and distribute test builds

### Play Store
- [ ] Create Google Play Developer account
- [ ] Create app listing
- [ ] Upload signed App Bundle
- [ ] Submit for review

## 📝 Notes

### Common Issues

1. **"Build failed due to use of deleted Android v1 embedding"**
   - This means Flutter infrastructure files are missing
   - Run: `flutter create . --org com.example --project-name smart_employee`
   - Then: `flutter pub get`

2. **"google-services.json not found"**
   - Download from Firebase Console → Project Settings → Android app

3. **"SHA1 fingerprint mismatch"**
   - Re-run `./gradlew signingReport` and update Firebase

4. **"Location permission denied"**
   - Go to app settings → Permissions → Location → Allow all the time

5. **"Firebase initialization failed"**
   - Ensure `firebase_options.dart` exists and is correctly generated

6. **"Build failed - Gradle error"**
   - Try `cd android && ./gradlew clean` then rebuild

### Support Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Flutter Docs](https://firebase.flutter.dev/docs/overview)
- [flutter_map](https://pub.dev/packages/flutter_map) - MapTiler integration (replaces Google Maps)
- [latlong2](https://pub.dev/packages/latlong2) - Geographic coordinates for flutter_map
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
