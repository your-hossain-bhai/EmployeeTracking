// employee_marker_info.dart
// Employee Marker Info Widget
// 
// A widget that displays detailed information about an employee
// when their marker is selected on the map.

import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../utils/extensions.dart';

/// Employee marker info panel for map view
class EmployeeMarkerInfo extends StatelessWidget {
  final EmployeeLocation employeeLocation;
  final VoidCallback? onClose;

  const EmployeeMarkerInfo({
    super.key,
    required this.employeeLocation,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  backgroundImage: employeeLocation.employee.photoUrl != null
                      ? NetworkImage(employeeLocation.employee.photoUrl!)
                      : null,
                  child: employeeLocation.employee.photoUrl == null
                      ? Text(
                          employeeLocation.employee.displayName[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeLocation.employee.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        employeeLocation.employee.email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                // Status
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.circle,
                    iconColor:
                        employeeLocation.isOnline ? Colors.green : Colors.orange,
                    label: 'Status',
                    value: employeeLocation.isOnline ? 'Online' : 'Offline',
                  ),
                ),
                // Last Update
                if (employeeLocation.location != null)
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.access_time,
                      iconColor: Colors.blue,
                      label: 'Last Update',
                      value:
                          employeeLocation.location!.timestamp.toTimeString(),
                    ),
                  ),
              ],
            ),
            if (employeeLocation.location != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // Accuracy
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.gps_fixed,
                      iconColor: Colors.green,
                      label: 'Accuracy',
                      value:
                          '${employeeLocation.location!.accuracy.toStringAsFixed(0)}m',
                    ),
                  ),
                  // Speed
                  if (employeeLocation.location!.speed != null)
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.speed,
                        iconColor: Colors.orange,
                        label: 'Speed',
                        value: employeeLocation.location!.speed!.toSpeedString(),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
