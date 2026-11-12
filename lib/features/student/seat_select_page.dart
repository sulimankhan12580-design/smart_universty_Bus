import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartbus/services/booking_service.dart';
import 'package:smartbus/shared/seat_map.dart';

class SeatSelectPage extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> trip;
  const SeatSelectPage({super.key, required this.tripId, required this.trip});

  @override
  State<SeatSelectPage> createState() => _SeatSelectPageState();
}

class _SeatSelectPageState extends State<SeatSelectPage> {
  int? _selected;
  bool _busy = false;

  Future<void> _book() async {
    setState(() => _busy = true);
        final seat = _selected!;
    final msg = ScaffoldMessenger.of(context);
    try {
      final r = await BookingService()
          .bookSeat(tripId: widget.tripId, seatNo: _selected!);
      if (!mounted) return;
      setState(() => _selected = null);
      final t = widget.trip;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Seat reserved'),
          content: Text(
            'Receipt No: ${r['receiptNo']}\n'
            'Student: ${r['studentName']} | Dept: ${r['department']}\n'
                        'Bus: ${t['busNumber']} | Seat: $seat\n'
            'Route: ${t['routeName']}\n'
            'Date/Time: ${t['date']} ${t['departureTime']}\n'
            'Fare: ${r['fare']} PKR (Cash, pay the conductor)\n'
            'Status: Reserved',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      msg.showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _busy = false);
  }


  Future<void> _cancel() async {
    setState(() => _busy = true);
    final msg = ScaffoldMessenger.of(context);
    try {
      await BookingService().cancelSeat(tripId: widget.tripId);
      msg.showSnackBar(const SnackBar(content: Text('Booking cancelled')));
    } catch (e) {
      msg.showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final t = widget.trip;
    return Scaffold(
      appBar: AppBar(title: Text('${t['routeName']}')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .doc(widget.tripId)
            .collection('seats')
            .snapshots(),
        builder: (context, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final statuses = <int, SeatStatus>{};
          int? mySeat;
          for (final d in s.data!.docs) {
            final no = int.parse(d.id);
            final data = d.data();
            final st = data['status'];
            if (st == 'reserved') statuses[no] = SeatStatus.reserved;
            if (st == 'boarded') statuses[no] = SeatStatus.boarded;
            if (data['studentId'] == uid && st != 'free') mySeat = no;
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${t['date']}  ${t['departureTime']}  -  Bus ${t['busNumber']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SeatMap(
                        statuses: statuses,
                        selectedSeat: mySeat ?? _selected,
                        onSeatTap: mySeat != null
                            ? null
                            : (n) => setState(
                                () => _selected = _selected == n ? null : n),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: mySeat != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Your seat: $mySeat',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _busy ? null : _cancel,
                              child: const Text('Cancel booking'),
                            ),
                          ],
                        )
                      : FilledButton(
                          onPressed:
                              (_selected == null || _busy) ? null : _book,
                          child: Text(_selected == null
                              ? 'Tap a seat'
                              : 'Confirm seat $_selected'),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}