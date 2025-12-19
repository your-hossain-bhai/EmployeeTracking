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
import '../../theme/app_theme.dart';
import '../../widgets/ui/primary_action_button.dart';
import '../../widgets/ui/quick_action_tile.dart';
import '../../widgets/ui/stat_chip.dart';
import '../../services/streak_service.dart';
import 'check_in_bottom_sheet.dart';

/// Employee dashboard page
class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  final _streakService = StreakService();
  int _currentStreak = 0;
  String? _currentBadge;
  String? _currentAttendanceId;

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
    _loadStreakData();
  }

  void _loadTodayAttendance() {
    final authState = context.read<AuthController>().state;
    if (authState is AuthAuthenticated) {
      context.read<AttendanceController>().add(
            AttendanceGetToday(employeeId: authState.user.id),
          );
    }
  }

  Future<void> _loadStreakData() async {
    final authState = context.read<AuthController>().state;
    if (authState is AuthAuthenticated) {
      final streak = await _streakService.calculateCurrentStreak(
        employeeId: authState.user.id,
        companyId: authState.user.companyId!,
      );
      final badge = await _streakService.getCurrentBadge(
        employeeId: authState.user.id,
        companyId: authState.user.companyId!,
      );
      if (mounted) {
        setState(() {
          _currentStreak = streak;
          _currentBadge = badge;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
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
          await _loadStreakData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
                decoration:
                    const BoxDecoration(gradient: AppTheme.headerGradient),
                child: BlocBuilder<AuthController, AuthState>(
                  builder: (context, state) {
                    final name = (state is AuthAuthenticated)
                        ? state.user.displayName
                        : 'Employee';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good Day,',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text(name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatChip(
                              icon: Icons.calendar_today,
                              label: DateTime.now().toDateString(),
                              color: Colors.white,
                            ),
                            BlocBuilder<AttendanceController, AttendanceState>(
                              builder: (context, st) {
                                var label = 'Not checked in';
                                var color = Colors.white;
                                if (st is AttendanceTodayLoaded &&
                                    st.attendance != null) {
                                  if (st.attendance!.checkOutTime != null) {
                                    label = 'Checked out';
                                  } else if (st.attendance!.checkInTime !=
                                      null) {
                                    label = 'Checked in';
                                  }
                                }
                                if (st is AttendanceCheckedIn)
                                  label = 'Checked in';
                                if (st is AttendanceCheckedOut)
                                  label = 'Checked out';
                                return StatChip(
                                    icon: Icons.verified,
                                    label: label,
                                    color: color);
                              },
                            ),
                            if (_currentStreak > 0)
                              StatChip(
                                icon: Icons.local_fire_department,
                                label:
                                    '$_currentStreak day${_currentStreak > 1 ? 's' : ''} streak',
                                color: Colors.amber,
                              ),
                            if (_currentBadge != null)
                              StatChip(
                                icon: Icons.emoji_events,
                                label: _currentBadge!,
                                color: Colors.greenAccent,
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Main content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCheckButton(context),
                    const SizedBox(height: 20),
                    _buildLocationTrackingCard(),
                    const SizedBox(height: 24),
                    Text('Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    GridView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                      ),
                      children: [
                        QuickActionTile(
                          icon: Icons.assignment_turned_in,
                          title: 'My Attendance',
                          subtitle: 'History & details',
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.myAttendance),
                        ),
                        QuickActionTile(
                          icon: Icons.event_note,
                          title: 'Submit Leave',
                          subtitle: 'Request time off',
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.employeeLeaveRequest),
                        ),
                        QuickActionTile(
                          icon: Icons.wallet_giftcard,
                          title: 'Leave Balance',
                          subtitle: 'Year to date',
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.employeeLeaveBalance),
                        ),
                        QuickActionTile(
                          icon: Icons.celebration,
                          title: 'Holidays',
                          subtitle: 'Upcoming days',
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.employeeHolidays),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
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
          _currentAttendanceId = attendance.id;
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

  Widget _buildHeroCheckButton(BuildContext context) {
    return BlocBuilder<AttendanceController, AttendanceState>(
      builder: (context, state) {
        bool isCheckedIn = false;
        if (state is AttendanceTodayLoaded && state.attendance != null) {
          isCheckedIn = state.attendance!.isCheckedIn;
        } else if (state is AttendanceCheckedIn) {
          isCheckedIn = true;
        } else if (state is AttendanceCheckedOut) {
          isCheckedIn = false;
        }

        return Center(
          child: PrimaryActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => BlocProvider.value(
                  value: context.read<AttendanceController>(),
                  child: CheckInBottomSheet(
                    isCheckOut: isCheckedIn,
                    attendanceId: isCheckedIn ? _currentAttendanceId : null,
                  ),
                ),
              );
            },
            label: isCheckedIn ? 'Check Out' : 'Check In',
            icon: isCheckedIn ? Icons.logout_rounded : Icons.login_rounded,
            danger: isCheckedIn,
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
