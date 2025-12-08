// admin_dashboard_page.dart
// Admin Dashboard Page
// 
// This page provides an overview for administrators including:
// - Employee statistics
// - Quick access to management features
// - Today's attendance summary

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/auth_controller.dart';
import '../../routes.dart';
import '../../widgets/dashboard_card.dart';

/// Admin dashboard page
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

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
        onRefresh: () async {
          // Refresh data
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
              Row(
                children: [
                  Expanded(
                    child: DashboardCard(
                      title: 'Total Employees',
                      value: '25',
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
                      value: '20',
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
                      value: '3',
                      icon: Icons.event_busy,
                      color: Colors.orange,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardCard(
                      title: 'Absent',
                      value: '2',
                      icon: Icons.cancel,
                      color: Colors.red,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
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
