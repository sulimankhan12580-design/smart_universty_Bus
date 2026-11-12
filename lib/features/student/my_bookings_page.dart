import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartbus/theme.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('studentId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!.docs.map((d) => d.data()).toList();
          String key(Map<String, dynamic> r) =>
              '${r['date'] ?? ''} ${r['time'] ?? ''}';
          list.sort((a, b) => key(b).compareTo(key(a)));

          final active = list.where((r) => r['status'] != 'cancelled').toList();
          final travelled =
              list.where((r) => r['status'] == 'boarded').toList();
          final km = travelled.fold<double>(
              0, (s, r) => s + ((r['km'] as num?)?.toDouble() ?? 0));
          final unpaid = active
              .where((r) => (r['paymentStatus'] ?? 'unpaid') == 'unpaid')
              .length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _stat('Booked', '${active.length}'),
                    _stat('Travelled', '${travelled.length}'),
                    _stat('KM', km.toStringAsFixed(1)),
                    _stat('Unpaid', '$unpaid'),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('No bookings yet'))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final r = list[i];
                          final status = '${r['status'] ?? ''}';
                          final pay = '${r['paymentStatus'] ?? 'unpaid'}';
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            child: ListTile(
                              title: Text('${r['routeName'] ?? 'Trip'}'),
                              subtitle: Text(
                                '${r['date'] ?? ''} ${r['time'] ?? ''}\n'
                                'Bus ${r['busNumber'] ?? ''} | '
                                'Seat ${r['seatNo'] ?? ''} | '
                                '${r['receiptNo'] ?? ''}\n'
                                'Fare: ${r['fare'] ?? ''} PKR ($pay)',
                              ),
                              isThreeLine: true,
                              trailing: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: status == 'cancelled'
                                      ? Colors.red
                                      : kGreen,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}