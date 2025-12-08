// routes.dart
// Application routing configuration
// 
// This file defines all named routes and the route generator
// for navigation throughout the application.

import 'package:flutter/material.dart';

import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/admin/employee_management_page.dart';
import 'pages/admin/live_tracking_page.dart';
import 'pages/admin/geofence_management_page.dart';
import 'pages/admin/attendance_reports_page.dart';
import 'pages/employee/employee_dashboard_page.dart';
import 'pages/employee/my_attendance_page.dart';
import 'pages/employee/check_in_page.dart';
import 'pages/employee/profile_page.dart';

/// Route names
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String adminDashboard = '/admin/dashboard';
  static const String employeeManagement = '/admin/employees';
  static const String liveTracking = '/admin/tracking';
  static const String geofenceManagement = '/admin/geofences';
  static const String attendanceReports = '/admin/attendance';
  static const String employeeDashboard = '/employee/dashboard';
  static const String myAttendance = '/employee/attendance';
  static const String checkIn = '/employee/checkin';
  static const String profile = '/employee/profile';
}

/// Route generator
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth routes
      case AppRoutes.login:
        return _buildRoute(const LoginPage(), settings);
      case AppRoutes.register:
        return _buildRoute(const RegisterPage(), settings);

      // Admin routes
      case AppRoutes.adminDashboard:
        return _buildRoute(const AdminDashboardPage(), settings);
      case AppRoutes.employeeManagement:
        return _buildRoute(const EmployeeManagementPage(), settings);
      case AppRoutes.liveTracking:
        return _buildRoute(const LiveTrackingPage(), settings);
      case AppRoutes.geofenceManagement:
        return _buildRoute(const GeofenceManagementPage(), settings);
      case AppRoutes.attendanceReports:
        return _buildRoute(const AttendanceReportsPage(), settings);

      // Employee routes
      case AppRoutes.employeeDashboard:
        return _buildRoute(const EmployeeDashboardPage(), settings);
      case AppRoutes.myAttendance:
        return _buildRoute(const MyAttendancePage(), settings);
      case AppRoutes.checkIn:
        return _buildRoute(const CheckInPage(), settings);
      case AppRoutes.profile:
        return _buildRoute(const ProfilePage(), settings);

      // Default route
      default:
        return _buildRoute(
          Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
          settings,
        );
    }
  }

  /// Build a material page route
  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
