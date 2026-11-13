import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartbus/theme.dart';

class DriverTripPage extends StatelessWidget {
  final String tripId;
  final String title;
  const DriverTripPage({super.key, required this.tripId, required this.title});

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> _board(String resId, dynamic seatNo) async {
    final b = _db.batch();
    b.update(_db.collection('reservations').doc(resId), {
      'status': 'boarded',
      'boardedAt': FieldValue.serverTimestamp(),
    });
    b.update(
      _db.collection('trips').doc(tripId).collection('seats').doc('$seatNo'),
      {'status': 'boarded'},
    );
    await b.commit();
  }

  Future<void> _pay(String resId) {
    return _db.collection('reservations').doc(resId).update({
      'paymentStatus': 'paid',
      'receivedBy': FirebaseAuth.instance.currentUser!.uid,
      'receivedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection('reservations')
            .where('tripId', isEqualTo: tripId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs
              .where((d) => d.data()['status'] != 'cancelled')
              .toList();
          docs.sort((a, b) => ((a.data()['seatNo'] ?? 0) as num)
              .compareTo((b.data()['seatNo'] ?? 0) as num));

          final onboard =
              docs.where((d) => d.data()['status'] == 'boarded').length;
          final paid =
              docs.where((d) => d.data()['paymentStatus'] == 'paid').length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _stat('Booked', '${docs.length}'),
                    _stat('Onboard', '$onboard'),
                    _stat('Paid', '$paid'),
                    _stat('Unpaid', '${docs.length - paid}'),
                  ],
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('No students booked yet'))
                    : ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final d = docs[i];
                          final r = d.data();
                          final boarded = r['status'] == 'boarded';
                          final isPaid = r['paymentStatus'] == 'paid';
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Seat ${r['seatNo']}  -  ${r['studentName'] ?? ''}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text('${r['department'] ?? ''}  |  '
                                      '${r['receiptNo'] ?? ''}'),
                                  Text('Fare: ${r['fare'] ?? ''} PKR'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (!boarded)
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                              minimumSize: const Size(0, 38)),
                                          onPressed: () =>
                                              _board(d.id, r['seatNo']),
                                          child: const Text('Boarded'),
                                        )
                                      else
                                        const Chip(label: Text('ONBOARD')),
                                      const SizedBox(width: 8),
                                      if (!isPaid)
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 38)),
                                          onPressed: () => _pay(d.id),
                                          child: const Text('Mark paid'),
                                        )
                                      else
                                        const Chip(label: Text('PAID')),
                                    ],
                                  ),
                                ],
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
                      fontSize: 20, fontWeight: FontWeight.bold, color: kNavy)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}