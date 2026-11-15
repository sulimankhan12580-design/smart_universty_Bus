
import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'gps_model.dart';
import 'gps_services.dart';
import 'gps_firestore_service.dart';

class GpsTrackingService {
  final GpsService _gpsService = GpsService();
  final GpsFirestoreService _firestoreService =
  GpsFirestoreService();

  StreamSubscription<Position>? _positionSubscription;

  Future<void> startTracking(String tripId) async {
    // Check GPS permission and get current location
    final initialPosition =
    await _gpsService.getCurrentLocation();

    // Stop previous tracking
    await stopTracking();

    // Upload initial location immediately
    await _uploadLocation(tripId, initialPosition);

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    // Start continuous location tracking
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
          (position) {
        _uploadLocation(tripId, position);
      },
      onError: (error) {
        print('GPS Tracking Error: $error');
      },
    );
  }

  Future<void> _uploadLocation(
      String tripId,
      Position position,
      ) async {
    try {
      final gpsData = GpsModel(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      await _firestoreService.updateTripLocation(
        tripId: tripId,
        location: gpsData,
      );

      print('GPS location uploaded successfully');
    } catch (error) {
      print('Firestore GPS Error: $error');
    }
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
