import 'package:smartbus/features/student/my_bookings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartbus/features/student/seat_select_page.dart';
import 'package:smartbus/services/auth_service.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student'),
        actions: [IconButton(
  icon: const Icon(Icons.receipt_long),
  tooltip: 'My Bookings',
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MyBookingsPage()),
  ),
),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('date', isGreaterThanOrEqualTo: _today)
            .orderBy('date')
            .snapshots(),
        builder: (context, s) {
          if (s.hasError) return Center(child: Text('Error: ${s.error}'));
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = s.data!.docs.where((d) {
            final st = d.data()['status'];
            return st == 'scheduled' || st == 'open' || st == 'running';
          }).toList()
            ..sort((a, b) {
              final x = '${a.data()['date']} ${a.data()['departureTime']}';
              final y = '${b.data()['date']} ${b.data()['departureTime']}';
              return x.compareTo(y);
            });
          if (docs.isEmpty) {
            return const Center(child: Text('No upcoming trips'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Upcoming trips',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final d in docs)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_bus),
                    title: Text('${d.data()['routeName']}'),
                    subtitle: Text(
                        '${d.data()['date']} ${d.data()['departureTime']}  -  Bus ${d.data()['busNumber']}\n${d.data()['reservedCount'] ?? 0} seats booked'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SeatSelectPage(tripId: d.id, trip: d.data()),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}