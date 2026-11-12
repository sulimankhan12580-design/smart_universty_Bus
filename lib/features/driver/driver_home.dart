
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'trip_detail.dart';
import 'manage_seats.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  // Open Trip Details
  Future<void> openTripDetails(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No trips found in database.'),
          ),
        );
        return;
      }

      final tripDoc = snapshot.docs.first;

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripDetailsScreen(
            tripId: tripDoc.id,
            tripData: tripDoc.data(),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading trip: $e'),
        ),
      );
    }
  }

  // Open Manage Seats
  Future<void> openManageSeats(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No trips found in database.'),
          ),
        );
        return;
      }

      final tripDoc = snapshot.docs.first;

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManageSeatsScreen(
            tripId: tripDoc.id,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading seats: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: const Color(0xFF1769D2),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .limit(1)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No trips available.'),
            );
          }

          final trip = snapshot.data!.docs.first.data();

          final busNumber = trip['busNumber'] ?? 'N/A';
          final routeName = trip['routeName'] ?? 'N/A';
          final departureTime = trip['departureTime'] ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Welcome Section
                const Text(
                  'Welcome, Driver!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Manage your university bus operations.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 20),

                // University Bus Card
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(18),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Row(
                          children: [
                            Icon(
                              Icons.directions_bus,
                              color: Color(0xFF1769D2),
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'University Bus',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        infoRow('Bus Number', busNumber.toString()),
                        infoRow('Route', routeName.toString()),
                        infoRow('Departure', departureTime.toString()),

                        const SizedBox(height: 15),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => openTripDetails(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1769D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(13),
                            ),
                            child: const Text('View Trip Details'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Seat Overview
                const Text(
                  'Seat Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: overviewCard(
                        'Total Seats',
                        '20',
                        Icons.event_seat,
                        Colors.blue,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: overviewCard(
                        'Reserved Seats',
                        '10',
                        Icons.bookmark,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Driver Controls
                const Text(
                  'Driver Controls',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                controlCard(
                  context,
                  Icons.event_seat,
                  'Manage Seats',
                  'View and update seat status',
                  onTap: () => openManageSeats(context),
                ),

                controlCard(
                  context,
                  Icons.people,
                  'Student Reservations',
                  'View student booking details',
                ),

                controlCard(
                  context,
                  Icons.directions_bus,
                  'Bus Information',
                  'View trip and bus details',
                  onTap: () => openTripDetails(context),
                ),

                controlCard(
                  context,
                  Icons.notifications,
                  'Notifications',
                  'View important notifications',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Information Row
  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Overview Card
  Widget overviewCard(
      String title,
      String count,
      IconData icon,
      Color color,
      ) {
    return Card(
      color: Colors.white,
      elevation: 1,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Icon(icon, color: color, size: 30),

            const SizedBox(height: 10),

            Text(
              count,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Driver Control Card
  Widget controlCard(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle, {
        VoidCallback? onTap,
      }) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF1769D2),
          size: 30,
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(subtitle),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),

        onTap: onTap,
      ),
    );
  }
}
