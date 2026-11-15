
import 'package:cloud_firestore/cloud_firestore.dart';

import 'gps_model.dart';

class GpsFirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // GPS location ko existing trip document mein save karna
  Future<void> updateTripLocation({
    required String tripId,
    required GpsModel location,
  }) async {
    await _firestore
        .collection('trips')
        .doc(tripId)
        .update({
      'lat': location.latitude,
      'lng': location.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
