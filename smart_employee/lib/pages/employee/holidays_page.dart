import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/auth_controller.dart';

class HolidaysPage extends StatelessWidget {
  const HolidaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>().state as AuthAuthenticated?;
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('holidays');
    if (auth != null && (auth.user.companyId ?? '').isNotEmpty) {
      q = q.where('companyId', isEqualTo: auth.user.companyId);
    }
    final stream = q.snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Holidays')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No holidays found. Enjoy your work!'),
            );
          }
          final items = snapshot.data!.docs
              .map((d) => d.data())
              .map((d) => (
                    (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    (d['name'] as String?) ?? 'Holiday',
                    (d['type'] as String?) ?? 'General',
                  ))
              .toList()
            ..sort((a, b) => a.$1.compareTo(b.$1));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final date = items[i].$1;
              final name = items[i].$2;
              final type = items[i].$3;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${date.day}'),
                  ),
                  title: Text(name),
                  subtitle: Text('${date.month}/${date.year} · $type'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
