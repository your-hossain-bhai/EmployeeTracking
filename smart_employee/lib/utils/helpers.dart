// helpers.dart
// Utility Helper Functions
// 
// This file contains helper functions used throughout the application
// for common operations like validation, formatting, and calculations.

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Validation helpers
class Validators {
  Validators._();

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}

/// Location helpers
class LocationHelpers {
  LocationHelpers._();

  /// Calculate distance between two coordinates in meters using Haversine formula
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  /// Check if a point is inside a circular geofence
  static bool isInsideGeofence({
    required double pointLat,
    required double pointLon,
    required double centerLat,
    required double centerLon,
    required double radiusMeters,
  }) {
    final distance = calculateDistance(
      lat1: pointLat,
      lon1: pointLon,
      lat2: centerLat,
      lon2: centerLon,
    );
    return distance <= radiusMeters;
  }

  /// Get bearing between two points in degrees
  static double getBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLon = _toRadians(lon2 - lon1);
    final y = math.sin(dLon) * math.cos(_toRadians(lat2));
    final x = math.cos(_toRadians(lat1)) * math.sin(_toRadians(lat2)) -
        math.sin(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.cos(dLon);
    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }
}

/// Date/Time helpers
class DateTimeHelpers {
  DateTimeHelpers._();

  /// Get list of dates between start and end (inclusive)
  static List<DateTime> getDateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDate)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Get start and end of current week
  static (DateTime, DateTime) getCurrentWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return (
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
    );
  }

  /// Get start and end of current month
  static (DateTime, DateTime) getCurrentMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return (startOfMonth, endOfMonth);
  }

  /// Parse time string (HH:mm) to TimeOfDay
  static TimeOfDay? parseTimeString(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  /// Format TimeOfDay to string (HH:mm)
  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Check if current time is within work hours
  static bool isWithinWorkHours({
    required String startTime,
    required String endTime,
    List<int>? workDays,
  }) {
    final now = DateTime.now();
    
    // Check if today is a work day
    if (workDays != null && !workDays.contains(now.weekday)) {
      return false;
    }

    final start = parseTimeString(startTime);
    final end = parseTimeString(endTime);
    
    if (start == null || end == null) return true;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }
}

/// UI helpers
class UIHelpers {
  UIHelpers._();

  /// Get status color based on attendance status
  static Color getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'checkedin':
        return Colors.green;
      case 'checkedout':
        return Colors.blue;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'halfday':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// Get status icon based on attendance status
  static IconData getAttendanceStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'checkedin':
        return Icons.login;
      case 'checkedout':
        return Icons.logout;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'halfday':
        return Icons.timelapse;
      default:
        return Icons.help_outline;
    }
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
