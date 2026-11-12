import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Books one seat. Throws a String message if it fails.
  /// Returns receipt details.
  Future<Map<String, dynamic>> bookSeat({
    required String tripId,
    required int seatNo,
  }) async {
    final uid = _auth.currentUser!.uid;
    final userSnap = await _db.collection('users').doc(uid).get();
    final u = userSnap.data() ?? {};

    final tripRef = _db.collection('trips').doc(tripId);
    final seatRef = tripRef.collection('seats').doc('$seatNo');
    final resRef = _db.collection('reservations').doc('${tripId}_$uid');

    return _db.runTransaction<Map<String, dynamic>>((tx) async {
      // ---- all reads first ----
      final tripSnap = await tx.get(tripRef);
      final seatSnap = await tx.get(seatRef);
      final resSnap = await tx.get(resRef);

      if (!tripSnap.exists) throw 'Trip not found';
      final trip = tripSnap.data()!;
      final status = trip['status'];
      if (status != 'scheduled' && status != 'open') {
        throw 'Booking is closed for this trip';
      }
      if (resSnap.exists) {
        final rs = resSnap.data()!['status'];
        if (rs == 'reserved' || rs == 'boarded') {
          throw 'You already have a seat on this trip';
        }
      }
      if (!seatSnap.exists || seatSnap.data()!['status'] != 'free') {
        throw 'Sorry, this seat was just taken. Please pick another seat.';
      }

      final date = trip['date'] as String;
      final dayKey = date.replaceAll('-', '');
      final counterRef = _db.collection('counters').doc(dayKey);
      final counterSnap = await tx.get(counterRef);
      final routeSnap =
          await tx.get(_db.collection('routes').doc(trip['routeId']));

      final n = ((counterSnap.data()?['receiptCount'] ?? 0) as int) + 1;
      final receiptNo = 'UVB-$dayKey-${n.toString().padLeft(4, '0')}';
      final fare = routeSnap.data()?['fare'] ?? 30;
      final km = routeSnap.data()?['distanceKm'] ?? 0;

      // ---- then all writes ----
      tx.update(seatRef, {
        'status': 'reserved',
        'studentId': uid,
        'studentName': u['name'],
      });
      tx.set(resRef, {
        'tripId': tripId,
        'busId': trip['busId'],
        'busNumber': trip['busNumber'],
        'routeId': trip['routeId'],
        'routeName': trip['routeName'],
        'departureTime': trip['departureTime'],
        'studentId': uid,
        'studentName': u['name'],
        'department': u['department'],
        'seatNo': seatNo,
        'status': 'reserved',
        'date': date,
        'month': date.substring(0, 7),
        'km': km,
        'fare': fare,
        'paymentStatus': 'unpaid',
        'receivedBy': null,
        'receivedAt': null,
        'receiptNo': receiptNo,
        'createdAt': FieldValue.serverTimestamp(),
        'cancelledAt': null,
      });
      tx.update(tripRef, {'reservedCount': FieldValue.increment(1)});
      tx.set(counterRef, {'receiptCount': n});

      return {
        'receiptNo': receiptNo,
        'fare': fare,
        'studentName': u['name'],
        'department': u['department'],
      };
    });
  }

  /// Cancels the current student's reservation on this trip.
  Future<void> cancelSeat({required String tripId}) async {
    final uid = _auth.currentUser!.uid;
    final tripRef = _db.collection('trips').doc(tripId);
    final resRef = _db.collection('reservations').doc('${tripId}_$uid');

    await _db.runTransaction((tx) async {
      final resSnap = await tx.get(resRef);
      if (!resSnap.exists || resSnap.data()!['status'] != 'reserved') {
        throw 'No active reservation to cancel';
      }
      final seatNo = resSnap.data()!['seatNo'];
      final seatRef = tripRef.collection('seats').doc('$seatNo');
      tx.update(seatRef, {
        'status': 'free',
        'studentId': null,
        'studentName': null,
      });
      tx.update(resRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      tx.update(tripRef, {'reservedCount': FieldValue.increment(-1)});
    });
  }
}