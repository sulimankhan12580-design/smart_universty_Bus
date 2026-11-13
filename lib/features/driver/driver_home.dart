import 'package:smartbus/features/driver/driver_trip_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartbus/services/auth_service.dart';
import 'package:smartbus/theme.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _setStatus(String tripId, String status) {
    return FirebaseFirestore.instance.collection('trips').doc(tripId).update({
      'status': status,
      if (status == 'running') 'startedAt': FieldValue.serverTimestamp(),
      if (status == 'completed') 'endedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('date', isEqualTo: _today)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs.where((d) {
            final id = d.data()['driverId'];
            return id == null || id == uid;
          }).toList();
          docs.sort((a, b) => '${a.data()['departureTime']}'
              .compareTo('${b.data()['departureTime']}'));

          if (docs.isEmpty) {
            return const Center(child: Text('No trips for today'));
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text("Today's trips ($_today)",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final d in docs) _tripCard(context, d),
            ],
          );
        },
      ),
    );
  }

  Widget _tripCard(
      BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final t = d.data();
    final status = '${t['status']}';
    final canStart = status == 'scheduled' || status == 'open';
    final running = status == 'running';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t['routeName'] ?? 'Trip'}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${t['departureTime']}  |  Bus ${t['busNumber']}'),
            Text('Seats booked: ${t['reservedCount'] ?? 0}'),
            Text('Status: ${status.toUpperCase()}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: status == 'completed' ? Colors.grey : kGreen)),
            const SizedBox(height: 10),
            OutlinedButton(
  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DriverTripPage(
        tripId: d.id,
        title: '${t['routeName']}  ${t['departureTime']}',
      ),
    ),
  ),
  child: const Text('Boarding list'),
),
const SizedBox(height: 8),
            if (canStart)
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                onPressed: () => _setStatus(d.id, 'running'),
                child: const Text('Start trip'),
              ),
            if (running)
              FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white),
                onPressed: () => _setStatus(d.id, 'completed'),
                child: const Text('End trip'),
              ),
          ],
        ),
      ),
    );
  }
}