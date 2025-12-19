// leave_management_page.dart
// Leave Management Page
// Allows employees to request leave and admins to approve/reject

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../controllers/auth_controller.dart';
import '../../models/leave_model.dart';
import '../../utils/extensions.dart';

class LeaveManagementPage extends StatefulWidget {
  const LeaveManagementPage({super.key});

  @override
  State<LeaveManagementPage> createState() => _LeaveManagementPageState();
}

class _LeaveManagementPageState extends State<LeaveManagementPage> {
  final _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all'; // all, pending, approved, rejected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showRequestLeaveDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', 'approved'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),
          // Leave List
          Expanded(
            child: _buildLeaveList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    return FilterChip(
      label: Text(label),
      selected: _filterStatus == status,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
    );
  }

  Widget _buildLeaveList() {
    return BlocBuilder<AuthController, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Not authenticated'));
        }

        final isAdmin = authState.user.isAdmin;
        final userId = authState.user.id;
        final companyId = authState.user.companyId;

        Query query = _firestore.collection('leaves').where(
              'companyId',
              isEqualTo: companyId,
            );

        if (!isAdmin) {
          query = query.where('employeeId', isEqualTo: userId);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Unable to load leave requests'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var leaves = snapshot.data!.docs
                .map((doc) => LeaveModel.fromFirestore(doc))
                .toList();

            // Filter by status
            if (_filterStatus != 'all') {
              leaves = leaves.where((leave) {
                return leave.status.name == _filterStatus;
              }).toList();
            }

            // Sort by date (newest first)
            leaves.sort((a, b) => b.startDate.compareTo(a.startDate));

            if (leaves.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_note, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _filterStatus == 'all'
                          ? 'No leave requests'
                          : 'No $_filterStatus leave requests',
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leaves.length,
              itemBuilder: (context, index) {
                final leave = leaves[index];
                return _buildLeaveCard(context, leave, isAdmin);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLeaveCard(
    BuildContext context,
    LeaveModel leave,
    bool isAdmin,
  ) {
    final formatter = DateFormat.yMMMd();
    final statusColor = leave.status == LeaveStatus.approved
        ? Colors.green
        : leave.status == LeaveStatus.rejected
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.type.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatter.format(leave.startDate)} - ${formatter.format(leave.endDate)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(leave.status.name),
                  backgroundColor: statusColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${leave.durationDays} day${leave.durationDays > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              leave.reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            if (isAdmin && leave.status == LeaveStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectLeave(leave),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveLeave(leave),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Approve'),
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

  void _showRequestLeaveDialog() {
    final startController = TextEditingController();
    final endController = TextEditingController();
    final reasonController = TextEditingController();
    LeaveType selectedType = LeaveType.vacation;
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Leave'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<LeaveType>(
                  isExpanded: true,
                  value: selectedType,
                  items: LeaveType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.name.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        startDate = date;
                        startController.text = DateFormat.yMMMd().format(date);
                      });
                    }
                  },
                  child: TextFormField(
                    controller: startController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        endDate = date;
                        endController.text = DateFormat.yMMMd().format(date);
                      });
                    }
                  },
                  child: TextFormField(
                    controller: endController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Why are you requesting leave?',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (startDate == null ||
                    endDate == null ||
                    reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final authState = context.read<AuthController>().state;
                if (authState is! AuthAuthenticated) return;

                final leave = LeaveModel(
                  id: const Uuid().v4(),
                  employeeId: authState.user.id,
                  companyId: authState.user.companyId,
                  type: selectedType,
                  startDate: startDate!,
                  endDate: endDate!,
                  reason: reasonController.text,
                  createdAt: DateTime.now(),
                );

                await _firestore
                    .collection('leaves')
                    .doc(leave.id)
                    .set(leave.toFirestore());

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Leave request submitted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveLeave(LeaveModel leave) async {
    final authState = context.read<AuthController>().state;
    if (authState is! AuthAuthenticated) return;

    await _firestore.collection('leaves').doc(leave.id).update({
      'status': 'approved',
      'approvedBy': authState.user.id,
      'approvedAt': Timestamp.now(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request approved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rejectLeave(LeaveModel leave) async {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Rejection Reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('leaves').doc(leave.id).update({
                'status': 'rejected',
                'rejectionReason': reasonController.text,
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Leave request rejected'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
