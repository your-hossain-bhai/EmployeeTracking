// attendance_reports_page.dart
// Attendance Reports Page
// 
// This page displays attendance reports for administrators.
// Features include daily/weekly/monthly reports, filtering,
// and export functionality.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../utils/extensions.dart';

/// Attendance reports page for admin
class AttendanceReportsPage extends StatefulWidget {
  const AttendanceReportsPage({super.key});

  @override
  State<AttendanceReportsPage> createState() => _AttendanceReportsPageState();
}

class _AttendanceReportsPageState extends State<AttendanceReportsPage> {
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'day'; // day, week, month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_view_day),
            onSelected: (value) {
              setState(() {
                _viewMode = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'day', child: Text('Daily')),
              const PopupMenuItem(value: 'week', child: Text('Weekly')),
              const PopupMenuItem(value: 'month', child: Text('Monthly')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _getPreviousDate();
                    });
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Text(
                    _getDateRangeText(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedDate.isBefore(
                    DateTime.now().subtract(const Duration(days: 1)),
                  )
                      ? () {
                          setState(() {
                            _selectedDate = _getNextDate();
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSummaryCards(),
          ),

          // Attendance List
          Expanded(
            child: _buildAttendanceList(),
          ),
        ],
      ),
    );
  }

  DateTime _getPreviousDate() {
    switch (_viewMode) {
      case 'week':
        return _selectedDate.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
      default:
        return _selectedDate.subtract(const Duration(days: 1));
    }
  }

  DateTime _getNextDate() {
    switch (_viewMode) {
      case 'week':
        return _selectedDate.add(const Duration(days: 7));
      case 'month':
        return DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      default:
        return _selectedDate.add(const Duration(days: 1));
    }
  }

  String _getDateRangeText() {
    final formatter = DateFormat.yMMMd();
    switch (_viewMode) {
      case 'week':
        final start =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${formatter.format(start)} - ${formatter.format(end)}';
      case 'month':
        return DateFormat.yMMM().format(_selectedDate);
      default:
        return formatter.format(_selectedDate);
    }
  }

  (DateTime, DateTime) _getDateRange() {
    switch (_viewMode) {
      case 'week':
        final start =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
        return (start, end);
      case 'month':
        final start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59);
        return (start, end);
      default:
        final start = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
        final end = start.add(const Duration(hours: 23, minutes: 59));
        return (start, end);
    }
  }

  Widget _buildSummaryCards() {
    return BlocBuilder<AuthController, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        final (startDate, endDate) = _getDateRange();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('attendance')
              .where('companyId', isEqualTo: authState.user.companyId)
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .snapshots(),
          builder: (context, snapshot) {
            int present = 0;
            int absent = 0;
            int late = 0;

            if (snapshot.hasData) {
              for (final doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String?;
                if (status == 'checkedIn' || status == 'checkedOut') {
                  present++;
                  // Check if late (after 9:15 AM)
                  final checkInTime = (data['checkInTime'] as Timestamp?)?.toDate();
                  if (checkInTime != null && checkInTime.hour >= 9 && checkInTime.minute > 15) {
                    late++;
                  }
                } else if (status == 'absent') {
                  absent++;
                }
              }
            }

            return Row(
              children: [
                _buildSummaryCard('Present', present.toString(), Colors.green),
                const SizedBox(width: 8),
                _buildSummaryCard('Absent', absent.toString(), Colors.red),
                const SizedBox(width: 8),
                _buildSummaryCard('Late', late.toString(), Colors.orange),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return BlocBuilder<AuthController, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Not authenticated'));
        }

        final (startDate, endDate) = _getDateRange();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('attendance')
              .where('companyId', isEqualTo: authState.user.companyId)
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final records = snapshot.data!.docs
                .map((doc) => AttendanceModel.fromFirestore(doc))
                .toList();

            if (records.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No attendance records', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return _buildAttendanceItem(record);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceItem(AttendanceModel record) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(record.employeeId)
          .get(),
      builder: (context, snapshot) {
        String employeeName = 'Loading...';
        if (snapshot.hasData && snapshot.data!.exists) {
          final user = UserModel.fromFirestore(snapshot.data!);
          employeeName = user.displayName;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(record.status).withOpacity(0.2),
              child: Icon(
                _getStatusIcon(record.status),
                color: _getStatusColor(record.status),
              ),
            ),
            title: Text(employeeName),
            subtitle: Text(
              'Check-in: ${record.checkInTime?.toTimeString() ?? 'N/A'} | '
              'Check-out: ${record.checkOutTime?.toTimeString() ?? 'N/A'}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  record.status.name,
                  style: TextStyle(
                    color: _getStatusColor(record.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (record.workDuration != null)
                  Text(
                    record.workDuration!.toHoursMinutes(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            onTap: () => _showRecordDetails(record),
          ),
        );
      },
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.checkedIn:
        return Colors.green;
      case AttendanceStatus.checkedOut:
        return Colors.blue;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.halfDay:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.checkedIn:
        return Icons.login;
      case AttendanceStatus.checkedOut:
        return Icons.logout;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.halfDay:
        return Icons.timelapse;
      default:
        return Icons.help;
    }
  }

  void _showRecordDetails(AttendanceModel record) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Date', record.date.toDateString()),
            _buildDetailRow(
              'Check-in',
              record.checkInTime?.toTimeString() ?? 'N/A',
            ),
            _buildDetailRow(
              'Check-out',
              record.checkOutTime?.toTimeString() ?? 'N/A',
            ),
            _buildDetailRow(
              'Duration',
              record.workDuration?.toHoursMinutes() ?? 'N/A',
            ),
            _buildDetailRow('Method', record.checkInMethod.name),
            _buildDetailRow(
              'Geofence Verified',
              record.isGeofenceVerified ? 'Yes' : 'No',
            ),
            if (record.isManuallyOverridden) ...[
              const Divider(),
              _buildDetailRow('Overridden', 'Yes'),
              _buildDetailRow('Override Reason', record.overrideReason ?? 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }
}
