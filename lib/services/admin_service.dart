import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final _db = FirebaseFirestore.instance;

  Future<void> addBus({required String busNumber}) {
    return _db.collection('buses').add({
      'busNumber': busNumber.trim(),
      'totalSeats': 48,
      'driverId': null,
      'isActive': true,
      'layout': {
        'frontSeats': 1,
        'rows': 8,
        'leftPerRow': 2,
        'rightPerRow': 3,
        'backSeats': 7,
      },
    });
  }

  Future<void> addRoute({
    required String name,
    required String startPoint,
    required String endPoint,
    required double distanceKm,
    required int fare,
  }) {
    return _db.collection('routes').add({
      'name': name.trim(),
      'startPoint': startPoint.trim(),
      'endPoint': endPoint.trim(),
      'distanceKm': distanceKm,
      'fare': fare,
      'isActive': true,
    });
  }

  /// Creates the trip and its seat documents (1..totalSeats, all free).
  Future<void> createTrip({
    required String busId,
    required String busNumber,
    required int totalSeats,
    required String routeId,
    required String routeName,
    String? driverId,
    String? driverName,
    required String date, // 2026-11-12
    required String departureTime, // 07:45
  }) async {
    final tripRef = _db.collection('trips').doc();
    final batch = _db.batch();
    batch.set(tripRef, {
      'busId': busId,
      'busNumber': busNumber,
      'routeId': routeId,
      'routeName': routeName,
      'driverId': driverId,
      'driverName': driverName,
      'date': date,
      'departureTime': departureTime,
      'status': 'scheduled',
      'reservedCount': 0,
      'boardedCount': 0,
      'totalKm': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    for (var i = 1; i <= totalSeats; i++) {
      batch.set(tripRef.collection('seats').doc('$i'), {
        'seatNo': i,
        'status': 'free',
        'studentId': null,
        'studentName': null,
      });
    }
    await batch.commit();
  }

  Future<void> approveUser(String uid) {
    return _db.collection('users').doc(uid).update({'status': 'active'});
  }
}