
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageSeatsScreen extends StatelessWidget {
  final String tripId;

  const ManageSeatsScreen({
    super.key,
    required this.tripId,
  });

  Future<void> updateSeatStatus(
      String seatId,
      String status,
      ) async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId)
        .collection('seats')
        .doc(seatId)
        .update({
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        title: const Text('Manage Seats'),
        backgroundColor: const Color(0xFF1769D2),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .doc(tripId)
            .collection('seats')
            .orderBy('seatNo')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No seats found.'),
            );
          }

          final seats = snapshot.data!.docs;

          final availableSeats = seats.where(
                (seat) => seat.data()['status'] == 'free',
          ).length;

          final reservedSeats = seats.where(
                (seat) => seat.data()['status'] == 'reserved',
          ).length;

          return Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'Seat Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _countCard(
                        'Available',
                        availableSeats,
                        Colors.green,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _countCard(
                        'Reserved',
                        reservedSeats,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                const Text(
                  'All Bus Seats',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Expanded(
                  child: GridView.builder(
                    itemCount: seats.length,

                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),

                    itemBuilder: (context, index) {
                      final seat = seats[index];
                      final data = seat.data();

                      final status =
                          data['status'] ?? 'free';

                      final seatNo =
                          data['seatNo']?.toString() ??
                              'N/A';

                      final isReserved =
                          status == 'reserved';

                      final color = isReserved
                          ? Colors.orange
                          : Colors.green;

                      return InkWell(
                        borderRadius: BorderRadius.circular(15),

                        onTap: () async {
                          final newStatus = isReserved
                              ? 'free'
                              : 'reserved';

                          try {
                            await updateSeatStatus(
                              seat.id,
                              newStatus,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Seat $seatNo updated to $newStatus',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                ),
                              );
                            }
                          }
                        },

                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius:
                            BorderRadius.circular(15),
                            border: Border.all(
                              color: color,
                              width: 1.5,
                            ),
                          ),

                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_seat,
                                color: color,
                                size: 32,
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Seat $seatNo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                isReserved
                                    ? 'Reserved'
                                    : 'Available',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _countCard(
      String title,
      int count,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),

      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
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
}
