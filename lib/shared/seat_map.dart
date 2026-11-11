import 'package:flutter/material.dart';
import 'package:smartbus/theme.dart';

enum SeatStatus { free, reserved, boarded }

/// Airline style seat map for the bus.
/// Seat 1 is beside the driver, then rows of (left | right), then the back seat.
class SeatMap extends StatelessWidget {
  final Map<int, SeatStatus> statuses; // seatNo -> status (missing = free)
  final int? selectedSeat;
  final ValueChanged<int>? onSeatTap;
  final bool tapAll; // false: only free seats can be tapped
  final int frontSeats;
  final int rows;
  final int leftPerRow;
  final int rightPerRow;
  final int backSeats;

  const SeatMap({
    super.key,
    required this.statuses,
    this.selectedSeat,
    this.onSeatTap,
    this.tapAll = false,
    this.frontSeats = 1,
    this.rows = 8,
    this.leftPerRow = 2,
    this.rightPerRow = 3,
    this.backSeats = 7,
  });

  Widget _seat(int no, double size) {
    final status = statuses[no] ?? SeatStatus.free;
    final selected = selectedSeat == no;
    Color bg;
    Color border;
    Color fg;
    if (selected) {
      bg = kGreen;
      border = kGreen;
      fg = Colors.black;
    } else if (status == SeatStatus.free) {
      bg = Colors.white;
      border = kGreen;
      fg = Colors.black;
    } else if (status == SeatStatus.reserved) {
      bg = Colors.grey.shade300;
      border = Colors.grey.shade400;
      fg = Colors.grey.shade700;
    } else {
      bg = kNavy;
      border = kNavy;
      fg = Colors.white;
    }
    final canTap = onSeatTap != null && (tapAll || status == SeatStatus.free);
    return GestureDetector(
      onTap: canTap ? () => onSeatTap!(no) : null,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$no',
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.34,
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color bg, Color border, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final avail = c.maxWidth - 28;
      final size = (avail / backSeats - 6).clamp(26.0, 44.0).toDouble();
      final perRow = leftPerRow + rightPerRow;
      final backStart = frontSeats + rows * perRow + 1;

      Widget seatRow(int r) {
        final start = frontSeats + r * perRow + 1;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < leftPerRow; i++) _seat(start + i, size),
            SizedBox(width: size * 0.8),
            for (var i = 0; i < rightPerRow; i++)
              _seat(start + leftPerRow + i, size),
          ],
        );
      }

      return Column(
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _legendItem(Colors.white, kGreen, 'Available'),
              _legendItem(kGreen, kGreen, 'Selected'),
              _legendItem(Colors.grey.shade300, Colors.grey.shade400, 'Booked'),
              _legendItem(kNavy, kNavy, 'Onboard'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kNavy, width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        for (var i = 1; i <= frontSeats; i++) _seat(i, size),
                      ],
                    ),
                    const Column(
                      children: [
                        Icon(Icons.account_circle, size: 32, color: kNavy),
                        Text('Driver', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                for (var r = 0; r < rows; r++) seatRow(r),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.keyboard_double_arrow_left,
                        size: 18, color: kNavy),
                    SizedBox(width: 4),
                    Text(
                      'DOOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kNavy,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < backSeats; i++)
                      _seat(backStart + i, size),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}