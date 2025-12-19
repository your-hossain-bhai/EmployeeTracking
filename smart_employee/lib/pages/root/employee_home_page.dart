// employee_home_page.dart
// Employee shell with bottom navigation

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/auth_controller.dart';
import '../../services/native_channel_service.dart';
import '../employee/employee_dashboard_page.dart';
import '../employee/my_attendance_page.dart';
import '../employee/profile_page.dart';
import '../employee/employee_live_map_page.dart';
import '../shared/alerts_page.dart';

/// Employee home scaffold with bottom navigation
class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      EmployeeDashboardPage(),
      EmployeeLiveMapPage(),
      MyAttendancePage(),
      AlertsPage(isAdmin: false),
      ProfilePage(),
    ];
    _startLocationTracking();
  }

  /// Start background location tracking for employee
  Future<void> _startLocationTracking() async {
    try {
      final authState = context.read<AuthController>().state;
      if (authState is! AuthAuthenticated) return;

      final nativeService = context.read<NativeChannelService>();
      await nativeService.initialize();

      // Start background location service (updates every 30s)
      final started = await nativeService.startLocationService(
        intervalMs: 30000, // 30 seconds
        fastestIntervalMs: 15000, // 15 seconds
        priority: 100, // High accuracy
      );

      if (started) {
        debugPrint('✅ Employee location tracking started');
      } else {
        debugPrint('⚠️ Failed to start location tracking');
      }
    } catch (e) {
      debugPrint('❌ Error starting location tracking: $e');
    }
  }

  @override
  void dispose() {
    // Stop tracking when leaving employee home
    _stopLocationTracking();
    super.dispose();
  }

  Future<void> _stopLocationTracking() async {
    try {
      final nativeService = context.read<NativeChannelService>();
      await nativeService.stopLocationService();
      debugPrint('🛑 Employee location tracking stopped');
    } catch (e) {
      debugPrint('Error stopping location tracking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Live Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.warning_amber_outlined),
              selectedIcon: Icon(Icons.warning_amber),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
