import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartbus/theme.dart';

num _n(dynamic v) => v is num ? v : 0;
String _two(int v) => v.toString().padLeft(2, '0');
String _ymd(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
String _ym(DateTime d) => '${d.year}-${_two(d.month)}';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: kGreen,
            tabs: const [Tab(text: 'Daily'), Tab(text: 'Monthly')],
          ),
        ),
        body: TabBarView(children: const [_DailyTab(), _MonthlyTab()]),
      ),
    );
  }
}

class _Live extends StatelessWidget {
  final String collection;
  final Widget Function(List<Map<String, dynamic>> docs) builder;
  const _Live(this.collection, this.builder);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return builder(
            snap.data!.docs.map((d) => {...d.data(), 'id': d.id}).toList());
      },
    );
  }
}

Widget _grid(List<List<String>> items) {
  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.9,
    children: [
      for (final i in items)
        Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(i[1],
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: kNavy)),
              const SizedBox(height: 4),
              Text(i[0], textAlign: TextAlign.center),
            ],
          ),
        ),
    ],
  );
}

List<List<String>> _stats(
    List<Map<String, dynamic>> trips, List<Map<String, dynamic>> res) {
  final active = res.where((r) => r['status'] != 'cancelled').toList();
  final boarded = active.where((r) => r['status'] == 'boarded').toList();
  final paid = active.where((r) => r['paymentStatus'] == 'paid').toList();
  final km = boarded.fold<num>(0, (s, r) => s + _n(r['km']));
  final cash = paid.fold<num>(0, (s, r) => s + _n(r['fare']));
  final done = trips.where((t) => t['status'] == 'completed').length;
  return [
    ['Trips (done / all)', '$done / ${trips.length}'],
    ['Bookings', '${active.length}'],
    ['Travelled', '${boarded.length}'],
    ['Total KM', km.toStringAsFixed(1)],
    ['Paid / Unpaid', '${paid.length} / ${active.length - paid.length}'],
    ['Cash collected (PKR)', '$cash'],
  ];
}

// ---------------- Daily ----------------
class _DailyTab extends StatefulWidget {
  const _DailyTab();

  @override
  State<_DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<_DailyTab> {
  DateTime _day = DateTime.now();

  Future<void> _pick() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (p != null) setState(() => _day = p);
  }

  @override
  Widget build(BuildContext context) {
    final d = _ymd(_day);
    return _Live(
      'trips',
      (allTrips) => _Live('reservations', (allRes) {
        final trips = allTrips.where((t) => t['date'] == d).toList();
        trips.sort((a, b) =>
            '${a['departureTime']}'.compareTo('${b['departureTime']}'));
        final res = allRes.where((r) => r['date'] == d).toList();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.calendar_today),
              label: Text('Date: $d'),
            ),
            const SizedBox(height: 10),
            _grid(_stats(trips, res)),
            const SizedBox(height: 12),
            const Text('Trips of the day',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (trips.isEmpty) const Text('No trips on this day'),
            for (final t in trips)
              Card(
                child: ListTile(
                  title: Text('${t['routeName']}'),
                  subtitle: Text('${t['departureTime']}  |  Bus ${t['busNumber']}'
                      '  |  Seats: ${t['reservedCount'] ?? 0}'),
                  trailing: Text('${t['status']}'.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ---------------- Monthly ----------------
class _MonthlyTab extends StatefulWidget {
  const _MonthlyTab();

  @override
  State<_MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends State<_MonthlyTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  @override
  Widget build(BuildContext context) {
    final m = _ym(_month);
    return _Live(
      'users',
      (users) => _Live(
        'trips',
        (allTrips) => _Live('reservations', (allRes) {
          final trips =
              allTrips.where((t) => '${t['date']}'.startsWith(m)).toList();
          final res = allRes.where((r) => r['month'] == m).toList();
          final active = res.where((r) => r['status'] != 'cancelled').toList();

          final reg = {for (final u in users) u['id']: u['isRegular'] != false};
          final regCount =
              active.where((r) => reg[r['studentId']] ?? true).length;

          // per-day breakdown: [trips, bookings, travelled, km]
          final days = <String, List<num>>{};
          for (final t in trips) {
            days.putIfAbsent('${t['date']}', () => <num>[0, 0, 0, 0])[0] += 1;
          }
          for (final r in active) {
            final e = days.putIfAbsent('${r['date']}', () => <num>[0, 0, 0, 0]);
            e[1] += 1;
            if (r['status'] == 'boarded') {
              e[2] += 1;
              e[3] += _n(r['km']);
            }
          }
          final keys = days.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: () => _shift(-1),
                      icon: const Icon(Icons.chevron_left)),
                  Text(m,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => _shift(1),
                      icon: const Icon(Icons.chevron_right)),
                ],
              ),
              _grid([
                ..._stats(trips, res),
                ['Regular students (trips)', '$regCount'],
                ['Non-regular (trips)', '${active.length - regCount}'],
              ]),
              const SizedBox(height: 12),
              const Text('Day by day',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (keys.isEmpty) const Text('No data this month'),
              for (final k in keys)
                Card(
                  child: ListTile(
                    title: Text(k),
                    subtitle: Text('Trips: ${days[k]![0]}   '
                        'Bookings: ${days[k]![1]}   '
                        'Travelled: ${days[k]![2]}   '
                        'KM: ${days[k]![3].toStringAsFixed(1)}'),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}