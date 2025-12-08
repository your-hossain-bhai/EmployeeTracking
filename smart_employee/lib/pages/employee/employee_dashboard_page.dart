// employee_dashboard_page.dart
// Employee Dashboard Page
// 
// This page provides an overview for employees including:
// - Today's attendance status
// - Quick check-in/check-out
// - Recent attendance history

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/location_controller.dart';
import '../../routes.dart';
import '../../utils/extensions.dart';

/// Employee dashboard page
class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  void _loadTodayAttendance() {
    final authState = context.read<AuthController>().state;
    if (authState is AuthAuthenticated) {
      context.read<AttendanceController>().add(
            AttendanceGetToday(employeeId: authState.user.id),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Stop location tracking before logout
              context.read<LocationController>().add(LocationStopTracking());
              context.read<AuthController>().add(AuthSignOutRequested());
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadTodayAttendance();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              BlocBuilder<AuthController, AuthState>(
                builder: (context, state) {
                  String name = 'Employee';
                  if (state is AuthAuthenticated) {
                    name = state.user.displayName;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $name',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateTime.now().toDateString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Attendance Status Card
              _buildAttendanceStatusCard(),
              const SizedBox(height: 24),

              // Location Tracking Status
              _buildLocationTrackingCard(),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.assignment,
                      title: 'My Attendance',
                      subtitle: 'View history',
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.myAttendance);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.qr_code_scanner,
                      title: 'Check In',
                      subtitle: 'Manual check-in',
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.checkIn);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatusCard() {
    return BlocBuilder<AttendanceController, AttendanceState>(
      builder: (context, state) {
        bool isCheckedIn = false;
        String? checkInTime;
        String? checkOutTime;
        String statusText = 'Not checked in';
        Color statusColor = Colors.grey;

        if (state is AttendanceTodayLoaded && state.attendance != null) {
          final attendance = state.attendance!;
          isCheckedIn = attendance.isCheckedIn;
          checkInTime = attendance.checkInTime?.toTimeString();
          checkOutTime = attendance.checkOutTime?.toTimeString();
          
          if (attendance.checkOutTime != null) {
            statusText = 'Checked out';
            statusColor = Colors.blue;
          } else if (attendance.checkInTime != null) {
            statusText = 'Checked in';
            statusColor = Colors.green;
          }
        } else if (state is AttendanceCheckedIn) {
          isCheckedIn = true;
          statusText = 'Checked in';
          statusColor = Colors.green;
          checkInTime = state.attendance.checkInTime?.toTimeString();
        } else if (state is AttendanceCheckedOut) {
          statusText = 'Checked out';
          statusColor = Colors.blue;
          checkInTime = state.attendance.checkInTime?.toTimeString();
          checkOutTime = state.attendance.checkOutTime?.toTimeString();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Status",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Check In',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            checkInTime ?? '--:--',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Check Out',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            checkOutTime ?? '--:--',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.checkIn);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCheckedIn ? Colors.red : Colors.green,
                    ),
                    child: Text(
                      isCheckedIn ? 'Check Out' : 'Check In',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationTrackingCard() {
    return BlocBuilder<LocationController, LocationState>(
      builder: (context, state) {
        bool isTracking = false;
        bool isPaused = false;
        String? lastUpdate;

        if (state is LocationTrackingActive) {
          isTracking = true;
          isPaused = state.isPaused;
          lastUpdate = state.currentLocation?.timestamp.toTimeString();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Location Tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: isTracking && !isPaused,
                      onChanged: (value) {
                        final authState = context.read<AuthController>().state;
                        if (authState is! AuthAuthenticated) return;

                        if (value) {
                          context.read<LocationController>().add(
                                LocationStartTracking(
                                  employeeId: authState.user.id,
                                ),
                              );
                        } else {
                          context.read<LocationController>().add(
                                LocationStopTracking(),
                              );
                        }
                      },
                    ),
                  ],
                ),
                if (isTracking) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isPaused ? Icons.pause_circle : Icons.play_circle,
                        color: isPaused ? Colors.orange : Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPaused ? 'Paused' : 'Active',
                        style: TextStyle(
                          color: isPaused ? Colors.orange : Colors.green,
                        ),
                      ),
                      if (lastUpdate != null) ...[
                        const SizedBox(width: 16),
                        Text(
                          'Last update: $lastUpdate',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Location tracking is required during work hours for attendance verification.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
