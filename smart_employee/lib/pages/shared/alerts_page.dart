// alerts_page.dart
// Alerts center showing attendance anomalies

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';

class AlertsPage extends StatelessWidget {
  final bool isAdmin;
  const AlertsPage({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthController>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    final service = context.read<AttendanceService>();
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Alerts' : 'My Alerts'),
      ),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: isAdmin
            ? service.streamTodayAttendance(user.companyId)
            : service.streamTodayAttendance(user.companyId).map(
                  (records) =>
                      records.where((r) => r.employeeId == user.id).toList(),
                ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No alerts right now. Everything looks good.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final alerts = snapshot.data!
              .where((record) => _isAlert(record))
              .toList()
            ..sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));

          if (alerts.isEmpty) {
            return const Center(
              child: Text('No active alerts'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = alerts[index];
              final severity = _alertSeverity(record);
              final subtitle = _alertMessage(record);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: severity.color.withOpacity(0.15),
                    child: Icon(
                      severity.icon,
                      color: severity.color,
                    ),
                  ),
                  title: Text(_statusLabel(record.status)),
                  subtitle: Text(subtitle),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _timeLabel(record),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Emp: ${record.employeeId.length > 6 ? record.employeeId.substring(0, 6) : record.employeeId}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isAlert(AttendanceModel record) {
    // Alert conditions: absent, missing checkout, outside geofence, unverified, or late (>9:15)
    if (record.status == AttendanceStatus.absent) return true;

    final now = DateTime.now();
    final checkInAge = record.checkInTime != null
        ? now.difference(record.checkInTime!)
        : Duration.zero;

    final missingCheckout =
        record.isCheckedIn && checkInAge > const Duration(hours: 10);
    final unverified = record.isCheckedIn && !record.isGeofenceVerified;
    final outsideGeofence = record.isCheckedIn && !record.isInsideGeofence;

    final lateArrival = record.checkInTime != null &&
        (record.checkInTime!.hour > 9 ||
            (record.checkInTime!.hour == 9 && record.checkInTime!.minute > 15));

    return missingCheckout || unverified || outsideGeofence || lateArrival;
  }

  _Severity _alertSeverity(AttendanceModel record) {
    if (record.status == AttendanceStatus.absent) {
      return const _Severity(Colors.red, Icons.block);
    }
    if (!record.isGeofenceVerified || !record.isInsideGeofence) {
      return const _Severity(Colors.red, Icons.location_off);
    }
    if (record.isCheckedIn) {
      return const _Severity(Colors.orange, Icons.access_time);
    }
    return const _Severity(Colors.amber, Icons.error_outline);
  }

  String _alertMessage(AttendanceModel record) {
    if (record.status == AttendanceStatus.absent) {
      return 'Marked absent today';
    }
    if (record.isCheckedIn && !record.isInsideGeofence) {
      return 'Checked in outside assigned site';
    }
    if (record.isCheckedIn && !record.isGeofenceVerified) {
      return 'Geofence not verified';
    }
    if (record.isCheckedIn) {
      return 'Checked in but no checkout yet';
    }
    return 'Check schedule and status';
  }

  String _statusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.checkedIn:
        return 'Checked In';
      case AttendanceStatus.checkedOut:
        return 'Checked Out';
      case AttendanceStatus.onBreak:
        return 'On Break';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.workFromHome:
        return 'Work From Home';
    }
  }

  String _timeLabel(AttendanceModel record) {
    if (record.checkInTime != null) {
      return 'In: ${_formatTime(record.checkInTime!)}';
    }
    return _formatTime(record.date);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _Severity {
  final Color color;
  final IconData icon;
  const _Severity(this.color, this.icon);
}
