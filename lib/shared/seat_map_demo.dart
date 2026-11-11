import 'package:flutter/material.dart';
import 'package:smartbus/shared/seat_map.dart';

class SeatMapDemo extends StatefulWidget {
  const SeatMapDemo({super.key});

  @override
  State<SeatMapDemo> createState() => _SeatMapDemoState();
}

class _SeatMapDemoState extends State<SeatMapDemo> {
  int? _selected;
  final Map<int, SeatStatus> _statuses = {
    1: SeatStatus.reserved,
    4: SeatStatus.reserved,
    5: SeatStatus.reserved,
    9: SeatStatus.boarded,
    14: SeatStatus.reserved,
    20: SeatStatus.reserved,
    27: SeatStatus.boarded,
    44: SeatStatus.reserved,
    45: SeatStatus.reserved,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select your seat')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SeatMap(
          statuses: _statuses,
          selectedSeat: _selected,
          onSeatTap: (n) =>
              setState(() => _selected = _selected == n ? null : n),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _selected == null ? null : () {},
            child: Text(
                _selected == null ? 'Tap a seat' : 'Confirm seat $_selected'),
          ),
        ),
      ),
    );
  }
}