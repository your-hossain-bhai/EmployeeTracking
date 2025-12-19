import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/auth_controller.dart';
import '../../models/leave_model.dart';

class LeaveBalancePage extends StatelessWidget {
  const LeaveBalancePage({super.key});

  int _countApprovedDays(Iterable<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year + 1, 1, 1);
    int days = 0;
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final status = (data['status'] as String?) ?? 'pending';
      if (status != LeaveStatus.approved.name) continue; // filter client-side
      final start = (data['startDate'] as Timestamp?)?.toDate();
      final end = (data['endDate'] as Timestamp?)?.toDate();
      if (start == null || end == null) continue;
      if (end.isBefore(yearStart) || start.isAfter(yearEnd)) continue;
      final from = start.isBefore(yearStart) ? yearStart : start;
      final to = end.isAfter(yearEnd) ? yearEnd : end;
      days += to.difference(from).inDays + 1;
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>().state as AuthAuthenticated?;
    if (auth == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final leaves = FirebaseFirestore.instance
        .collection('leaves')
        .where('employeeId', isEqualTo: auth.user.id)
        .snapshots();

    const yearlyAllowance =
        12 * 2; // example: 24 days/year (configurable later)

    return Scaffold(
      appBar: AppBar(title: const Text('Leave Balance')),
      body: StreamBuilder<QuerySnapshot>(
        stream: leaves,
        builder: (context, snapshot) {
          final used =
              snapshot.hasData ? _countApprovedDays(snapshot.data!.docs) : 0;
          final remaining = (yearlyAllowance - used).clamp(0, yearlyAllowance);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('$remaining',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('Days remaining in current year'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: used == 0 && yearlyAllowance == 0
                              ? 0
                              : used / yearlyAllowance,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 6),
                        Text('Used: $used / $yearlyAllowance days'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Recent Approved Leaves',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Expanded(
                  child: snapshot.hasData
                      ? ListView(
                          children: snapshot.data!.docs
                              .map((d) {
                                final lm = LeaveModel.fromFirestore(d);
                                if (lm.status != LeaveStatus.approved)
                                  return const SizedBox.shrink();
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.event_available),
                                    title: Text(
                                        '${lm.type.name.toUpperCase()} · ${lm.durationDays} days'),
                                    subtitle: Text(
                                      '${lm.startDate.toLocal().toString().split(' ').first} → ${lm.endDate.toLocal().toString().split(' ').first}',
                                    ),
                                  ),
                                );
                              })
                              .whereType<Widget>()
                              .toList(),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
