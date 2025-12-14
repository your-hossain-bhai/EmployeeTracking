// admin_dashboard_page.dart
// Admin Dashboard Page
//
// This page provides an overview for administrators including:
// - Employee statistics
// - Quick access to management features
// - Today's attendance summary

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/auth_controller.dart';
import '../../routes.dart';
import '../../widgets/dashboard_card.dart';

/// Admin dashboard page
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _totalEmployees = 0;
  int _presentToday = 0;
  int _onLeave = 0;
  int _absent = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // Get company ID from current user
      final authState = context.read<AuthController>().state;
      String? companyId;
      if (authState is AuthAuthenticated) {
        companyId = authState.user.companyId;
      }

      // Get total employees
      final employeesQuery = companyId != null
          ? _firestore
              .collection('users')
              .where('companyId', isEqualTo: companyId)
          : _firestore.collection('users');
      final employeesSnapshot = await employeesQuery.get();
      _totalEmployees = employeesSnapshot.docs.length;

      // Get today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get today's attendance
      final attendanceQuery = _firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd));

      final attendanceSnapshot = await attendanceQuery.get();

      // Count unique employees who checked in today
      final checkedInEmployees = <String>{};
      for (final doc in attendanceSnapshot.docs) {
        final employeeId = doc.data()['employeeId'] as String?;
        if (employeeId != null) {
          checkedInEmployees.add(employeeId);
        }
      }
      _presentToday = checkedInEmployees.length;

      // Calculate absent (total - present - on leave)
      // For now, we assume on leave is 0 unless we have a leave management system
      _onLeave = 0;
      _absent = (_totalEmployees - _presentToday - _onLeave)
          .clamp(0, _totalEmployees);
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthController>().add(AuthSignOutRequested());
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              BlocBuilder<AuthController, AuthState>(
                builder: (context, state) {
                  String name = 'Admin';
                  if (state is AuthAuthenticated) {
                    name = state.user.displayName;
                  }
                  return Text(
                    'Welcome, $name',
                    style: Theme.of(context).textTheme.headlineSmall,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Here\'s what\'s happening today',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 24),

              // Statistics Cards
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: DashboardCard(
                        title: 'Total Employees',
                        value: '$_totalEmployees',
                        icon: Icons.people,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(AppRoutes.employeeManagement);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardCard(
                        title: 'Present Today',
                        value: '$_presentToday',
                        icon: Icons.check_circle,
                        color: Colors.green,
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(AppRoutes.attendanceReports);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DashboardCard(
                        title: 'On Leave',
                        value: '$_onLeave',
                        icon: Icons.event_busy,
                        color: Colors.orange,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardCard(
                        title: 'Absent',
                        value: '$_absent',
                        icon: Icons.cancel,
                        color: Colors.red,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              _buildActionTile(
                context,
                icon: Icons.location_on,
                title: 'Live Tracking',
                subtitle: 'View real-time employee locations',
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.liveTracking);
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.map,
                title: 'Geofence Management',
                subtitle: 'Manage office locations and geofences',
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.geofenceManagement);
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.assignment,
                title: 'Attendance Reports',
                subtitle: 'View and export attendance data',
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.attendanceReports);
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.people,
                title: 'Employee Management',
                subtitle: 'Add, edit, or remove employees',
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.employeeManagement);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
