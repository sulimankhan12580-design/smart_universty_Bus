import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartbus/theme.dart';

num _n(dynamic v) => v is num ? v : 0;

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: kGreen,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Students'),
              Tab(text: 'Drivers'),
              Tab(text: 'Trips'),
            ],
          ),
        ),
        body: TabBarView(
          children: const [_Overview(), _Students(), _Drivers(), _Trips()],
        ),
      ),
    );
  }
}

/// Streams one collection and gives the docs (with 'id') to the builder.
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

Widget _card(String label, String value) {
  return Card(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}

// ---------------- Overview ----------------
class _Overview extends StatelessWidget {
  const _Overview();

  @override
  Widget build(BuildContext context) {
    return _Live(
      'users',
      (users) => _Live(
        'buses',
        (buses) => _Live(
          'trips',
          (trips) => _Live('reservations', (res) {
            final active = res.where((r) => r['status'] != 'cancelled');
            final boarded = res.where((r) => r['status'] == 'boarded');
            final paid = active.where((r) => r['paymentStatus'] == 'paid');
            final unpaid = active.where((r) => r['paymentStatus'] != 'paid');
            final collected = paid.fold<num>(0, (s, r) => s + _n(r['fare']));
            final due = unpaid.fold<num>(0, (s, r) => s + _n(r['fare']));
            final km = boarded.fold<num>(0, (s, r) => s + _n(r['km']));
            final completed =
                trips.where((t) => t['status'] == 'completed').length;
            return GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _card('Students',
                    '${users.where((u) => u['role'] == 'student').length}'),
                _card('Drivers',
                    '${users.where((u) => u['role'] == 'driver').length}'),
                _card('Buses', '${buses.length}'),
                _card('Trips (done / all)', '$completed / ${trips.length}'),
                _card('Bookings', '${active.length}'),
                _card('Travelled', '${boarded.length}'),
                _card('Total KM', km.toStringAsFixed(1)),
                _card('Paid / Unpaid', '${paid.length} / ${unpaid.length}'),
                _card('Cash collected (PKR)', '$collected'),
                _card('Cash pending (PKR)', '$due'),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ---------------- Students ----------------
class _Students extends StatelessWidget {
  const _Students();

  @override
  Widget build(BuildContext context) {
    return _Live(
      'users',
      (users) => _Live('reservations', (res) {
        final students = users.where((u) => u['role'] == 'student').toList();
        students.sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
        if (students.isEmpty) {
          return const Center(child: Text('No students yet'));
        }
        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, i) {
            final u = students[i];
            final mine = res.where(
                (r) => r['studentId'] == u['id'] && r['status'] != 'cancelled');
            final travelled = mine.where((r) => r['status'] == 'boarded');
            final paid = mine.where((r) => r['paymentStatus'] == 'paid').length;
            final km = travelled.fold<num>(0, (s, r) => s + _n(r['km']));
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: ListTile(
                title: Text('${u['name']}'),
                subtitle: Text('${u['department'] ?? ''}  |  '
                    '${u['isRegular'] == false ? 'Non-regular' : 'Regular'}\n'
                    'Booked: ${mine.length}  Travelled: ${travelled.length}  '
                    'KM: ${km.toStringAsFixed(1)}\n'
                    'Paid: $paid  Unpaid: ${mine.length - paid}'),
                isThreeLine: true,
              ),
            );
          },
        );
      }),
    );
  }
}

// ---------------- Drivers ----------------
class _Drivers extends StatelessWidget {
  const _Drivers();

  @override
  Widget build(BuildContext context) {
    return _Live('users', (users) {
      final drivers = users.where((u) => u['role'] == 'driver').toList();
      if (drivers.isEmpty) return const Center(child: Text('No drivers yet'));
      return ListView.builder(
        itemCount: drivers.length,
        itemBuilder: (context, i) {
          final d = drivers[i];
          final active = d['status'] == 'active';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: ListTile(
              leading: const Icon(Icons.directions_bus),
              title: Text('${d['name']}'),
              subtitle: Text('${d['department'] ?? ''}'),
              trailing: Text(
                active ? 'ACTIVE' : 'PENDING',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: active ? kGreen : Colors.orange),
              ),
            ),
          );
        },
      );
    });
  }
}

// ---------------- Trips ----------------
class _Trips extends StatelessWidget {
  const _Trips();

  @override
  Widget build(BuildContext context) {
    return _Live('trips', (trips) {
      trips.sort((a, b) => '${b['date']} ${b['departureTime']}'
          .compareTo('${a['date']} ${a['departureTime']}'));
      if (trips.isEmpty) return const Center(child: Text('No trips yet'));
      return ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, i) {
          final t = trips[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: ListTile(
              title: Text('${t['routeName']}'),
              subtitle: Text('${t['date']} ${t['departureTime']}  |  '
                  'Bus ${t['busNumber']}\n'
                  'Seats booked: ${t['reservedCount'] ?? 0}'),
              isThreeLine: true,
              trailing: Text('${t['status']}'.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      );
    });
  }
}