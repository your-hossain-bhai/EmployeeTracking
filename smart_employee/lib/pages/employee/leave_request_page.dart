import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/auth_controller.dart';
import '../../models/leave_model.dart';

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  LeaveType _type = LeaveType.vacation;
  DateTime? _start;
  DateTime? _end;
  final _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _start != null && _end != null
          ? DateTimeRange(start: _start!, end: _end!)
          : null,
    );
    if (range != null) {
      setState(() {
        _start = DateTime(range.start.year, range.start.month, range.start.day);
        _end = DateTime(range.end.year, range.end.month, range.end.day);
      });
    }
  }

  Future<void> _submit() async {
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range')),
      );
      return;
    }
    final auth = context.read<AuthController>().state;
    if (auth is! AuthAuthenticated) return;

    setState(() => _submitting = true);
    try {
      final doc = FirebaseFirestore.instance.collection('leaves').doc();
      final leave = LeaveModel(
        id: doc.id,
        employeeId: auth.user.id,
        companyId: auth.user.companyId ?? '',
        type: _type,
        startDate: _start!,
        endDate: _end!,
        reason: _reasonController.text.trim(),
        status: LeaveStatus.pending,
        createdAt: DateTime.now(),
      );
      await doc.set(leave.toFirestore());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted for approval')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Leave')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<LeaveType>(
              value: _type,
              items: LeaveType.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child:
                            Text(e.name[0].toUpperCase() + e.name.substring(1)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
              decoration: const InputDecoration(labelText: 'Leave Type'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              onTap: _pickRange,
              decoration: InputDecoration(
                labelText: 'Date Range',
                hintText: _start == null
                    ? 'Select dates'
                    : '${_start!.toLocal().toString().split(' ').first}  →  ${_end!.toLocal().toString().split(' ').first}',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.send),
                label:
                    Text(_submitting ? 'Submitting...' : 'Submit for Approval'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
