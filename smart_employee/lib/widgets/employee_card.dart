// employee_card.dart
// Employee Card Widget
// 
// A reusable card widget for displaying employee information
// in lists and grids.

import 'package:flutter/material.dart';

import '../models/user_model.dart';

/// Employee card for displaying employee information
class EmployeeCard extends StatelessWidget {
  final UserModel employee;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const EmployeeCard({
    super.key,
    required this.employee,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage:
              employee.photoUrl != null ? NetworkImage(employee.photoUrl!) : null,
          child: employee.photoUrl == null
              ? Text(
                  employee.displayName[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          employee.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: employee.isActive ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  employee.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color: employee.isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: onEdit != null
            ? IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              )
            : const Icon(Icons.chevron_right),
        isThreeLine: true,
      ),
    );
  }
}
