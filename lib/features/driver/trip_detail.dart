
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TripDetailsScreen extends StatelessWidget {
  final String tripId;
  final Map<String, dynamic> tripData;

  const TripDetailsScreen({
    super.key,
    required this.tripId,
    required this.tripData,
  });

  Future<void> updateTripStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId)
        .update({
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .doc(tripId)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Trip not found'),
            );
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          final status = data['status'] ?? 'scheduled';

          return Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Trip Information',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _infoRow('Bus Number', data['busNumber']),
                _infoRow('Route', data['routeName']),
                _infoRow('Departure Time', data['departureTime']),
                _infoRow('Driver Name', data['driverName']),
                _infoRow('Status', status),

                const Spacer(),

                if (status != 'completed')
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == 'running'
                            ? Colors.red
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),

                      onPressed: () async {
                        final newStatus = status == 'running'
                            ? 'completed'
                            : 'running';

                        try {
                          await updateTripStatus(newStatus);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  newStatus == 'running'
                                      ? 'Trip started!'
                                      : 'Trip completed!',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                              ),
                            );
                          }
                        }
                      },

                      child: Text(
                        status == 'running'
                            ? 'End Trip'
                            : 'Start Trip',
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}
