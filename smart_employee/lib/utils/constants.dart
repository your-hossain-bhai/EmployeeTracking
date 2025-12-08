// constants.dart
// Application Constants
// 
// This file contains all constant values used throughout the application
// including colors, strings, API endpoints, and configuration values.

import 'package:flutter/material.dart';

/// Application constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Smart Employee';
  static const String appVersion = '1.0.0';
  static const String packageId = 'com.example.smart_employee';

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // Attendance status colors
  static const Color checkedInColor = Color(0xFF4CAF50);
  static const Color checkedOutColor = Color(0xFF2196F3);
  static const Color absentColor = Color(0xFFB00020);
  static const Color lateColor = Color(0xFFFF9800);

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Location Settings
  static const int defaultLocationIntervalSeconds = 30;
  static const int defaultFastestLocationIntervalSeconds = 15;
  static const double defaultGeofenceRadiusMeters = 100.0;
  static const double minGeofenceRadiusMeters = 50.0;
  static const double maxGeofenceRadiusMeters = 1000.0;

  // Data Retention
  static const int locationRetentionDays = 90;
  static const int attendanceRetentionDays = 365;

  // Sync Settings
  static const int syncBatchSize = 50;
  static const int syncIntervalMinutes = 15;

  // Work Hours Defaults
  static const String defaultWorkStartTime = '09:00';
  static const String defaultWorkEndTime = '18:00';
  static const List<int> defaultWorkDays = [1, 2, 3, 4, 5]; // Mon-Fri

  // Map Settings
  static const double defaultMapZoom = 15.0;
  static const double minMapZoom = 5.0;
  static const double maxMapZoom = 20.0;

  // Notification Channel IDs
  static const String locationNotificationChannelId = 'location_tracking';
  static const String attendanceNotificationChannelId = 'attendance';
  static const String geofenceNotificationChannelId = 'geofence';

  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String companiesCollection = 'companies';
  static const String locationsCollection = 'locations';
  static const String attendanceCollection = 'attendance';
  static const String geofencesCollection = 'geofences';

  // Storage Paths
  static const String attendanceProofsPath = 'attendance_proofs';
  static const String profilePhotosPath = 'profile_photos';
}

/// Strings used in the application
class AppStrings {
  AppStrings._();

  // Auth
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String adminDashboard = 'Admin Dashboard';
  static const String employeeDashboard = 'Employee Dashboard';

  // Attendance
  static const String attendance = 'Attendance';
  static const String checkIn = 'Check In';
  static const String checkOut = 'Check Out';
  static const String checkedIn = 'Checked In';
  static const String checkedOut = 'Checked Out';
  static const String notCheckedIn = 'Not Checked In';
  static const String attendanceHistory = 'Attendance History';

  // Location
  static const String location = 'Location';
  static const String liveTracking = 'Live Tracking';
  static const String locationHistory = 'Location History';
  static const String startTracking = 'Start Tracking';
  static const String stopTracking = 'Stop Tracking';

  // Geofence
  static const String geofence = 'Geofence';
  static const String geofences = 'Geofences';
  static const String addGeofence = 'Add Geofence';
  static const String editGeofence = 'Edit Geofence';
  static const String removeGeofence = 'Remove Geofence';

  // Employees
  static const String employees = 'Employees';
  static const String addEmployee = 'Add Employee';
  static const String editEmployee = 'Edit Employee';
  static const String employeeDetails = 'Employee Details';

  // Common
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String confirm = 'Confirm';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String warning = 'Warning';
  static const String retry = 'Retry';
  static const String noData = 'No Data';

  // Errors
  static const String errorGeneric = 'Something went wrong';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorLocation = 'Could not get location';
  static const String errorPermission = 'Permission denied';
}
