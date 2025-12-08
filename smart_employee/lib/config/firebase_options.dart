// firebase_options.dart
// Firebase Configuration
// 
// NOTE: This file contains placeholder values. 
// Run `flutterfire configure` to generate real Firebase configuration.
// 
// For development/demo purposes, this file allows the app to compile
// but Firebase features will not work until configured properly.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for the current platform
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Placeholder values - run `flutterfire configure` to get real values
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:web:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'smart-employee-placeholder',
    authDomain: 'smart-employee-placeholder.firebaseapp.com',
    storageBucket: 'smart-employee-placeholder.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:android:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'smart-employee-placeholder',
    storageBucket: 'smart-employee-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:ios:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'smart-employee-placeholder',
    storageBucket: 'smart-employee-placeholder.appspot.com',
    iosBundleId: 'com.example.smartEmployee',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:macos:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'smart-employee-placeholder',
    storageBucket: 'smart-employee-placeholder.appspot.com',
    iosBundleId: 'com.example.smartEmployee',
  );
}
