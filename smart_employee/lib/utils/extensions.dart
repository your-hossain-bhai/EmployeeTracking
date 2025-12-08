// extensions.dart
// Dart/Flutter Extensions
// 
// This file contains extension methods on common types
// to provide utility functionality throughout the application.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Format as date string (e.g., "Jan 15, 2024")
  String toDateString() {
    return DateFormat.yMMMd().format(this);
  }

  /// Format as time string (e.g., "09:30 AM")
  String toTimeString() {
    return DateFormat.jm().format(this);
  }

  /// Format as date and time string (e.g., "Jan 15, 2024 09:30 AM")
  String toDateTimeString() {
    return DateFormat.yMMMd().add_jm().format(this);
  }

  /// Format as short date (e.g., "15 Jan")
  String toShortDateString() {
    return DateFormat('d MMM').format(this);
  }

  /// Format as ISO date only (e.g., "2024-01-15")
  String toIsoDateString() {
    return DateFormat('yyyy-MM-dd').format(this);
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Get relative time string (e.g., "2 hours ago")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${difference.inDays ~/ 365} year${difference.inDays ~/ 365 > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} month${difference.inDays ~/ 30 > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Duration extensions
extension DurationExtensions on Duration {
  /// Format as hours and minutes (e.g., "8h 30m")
  String toHoursMinutes() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Format as work duration (e.g., "8:30")
  String toWorkDuration() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }
}

/// String extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if string is a valid phone number
  bool get isValidPhone {
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(this);
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

/// Double extensions for coordinates
extension DoubleExtensions on double {
  /// Format as coordinate string (6 decimal places)
  String toCoordinateString() {
    return toStringAsFixed(6);
  }

  /// Format as distance (meters or km)
  String toDistanceString() {
    if (this < 1000) {
      return '${toStringAsFixed(0)} m';
    }
    return '${(this / 1000).toStringAsFixed(2)} km';
  }

  /// Format as speed (m/s to km/h)
  String toSpeedString() {
    final kmh = this * 3.6;
    return '${kmh.toStringAsFixed(1)} km/h';
  }
}

/// BuildContext extensions
extension BuildContextExtensions on BuildContext {
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Show snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  /// Show loading dialog
  void showLoading([String? message]) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message ?? 'Loading...'),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  void hideLoading() {
    Navigator.of(this).pop();
  }
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Get element at index or null
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
