
import 'package:flutter/material.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1769D2),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Driver Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Welcome, Driver!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Manage your university bus',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // Bus Information Card

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1769D2),
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 40,
                  ),

                  SizedBox(height: 12),

                  Text(
                    'University Bus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'Bus No: BUS-01',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  Text(
                    'Route: University Route',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Seat Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [

                Expanded(
                  child: seatCard(
                    'Available',
                    '20',
                    Colors.green,
                    Icons.event_seat,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: seatCard(
                    'Booked',
                    '10',
                    Colors.orange,
                    Icons.airline_seat_recline_normal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'Driver Controls',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            controlCard(
              Icons.event_seat,
              'Manage Seats',
              'View and update seat status',
            ),

            controlCard(
              Icons.people,
              'Student Reservations',
              'Check reserved student seats',
            ),

            controlCard(
              Icons.directions_bus,
              'Bus Information',
              'View bus details and route',
            ),

            controlCard(
              Icons.notifications_active,
              'Notifications',
              'Manage student notifications',
            ),
          ],
        ),
      ),
    );
  }

  Widget seatCard(
      String title,
      String count,
      Color color,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),

      child: Column(
        children: [

          Icon(icon, color: color, size: 30),

          const SizedBox(height: 10),

          Text(
            count,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            title,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  Widget controlCard(
      IconData icon,
      String title,
      String subtitle,
      ) {
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

        onTap: () {},
      ),
    );
  }
}
