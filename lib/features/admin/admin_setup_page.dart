import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartbus/services/admin_service.dart';

typedef Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

String _s(dynamic v) => v == null ? '' : '$v';

class AdminSetupPage extends StatelessWidget {
  const AdminSetupPage({super.key});

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      );

  Future<List<String>?> _ask(
    BuildContext context,
    String title,
    List<String> labels, {
    List<String>? initial,
  }) {
    final ctrls = [
      for (var i = 0; i < labels.length; i++)
        TextEditingController(text: initial != null ? initial[i] : ''),
    ];
    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: ctrls[i],
                    decoration: InputDecoration(labelText: labels[i]),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, [for (final c in ctrls) c.text.trim()]),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addBus(BuildContext context) async {
    final r = await _ask(context, 'Add bus', ['Bus number']);
    if (r != null && r[0].isNotEmpty) {
      await AdminService().addBus(busNumber: r[0]);
    }
  }

  Future<void> _addRoute(BuildContext context) async {
    final r = await _ask(
      context,
      'Add route',
      ['Route name', 'Start point', 'End point', 'Distance (km)', 'Fare (PKR)'],
      initial: ['', '', '', '', '30'],
    );
    if (r != null && r[0].isNotEmpty) {
      await AdminService().addRoute(
        name: r[0],
        startPoint: r[1],
        endPoint: r[2],
        distanceKm: double.tryParse(r[3]) ?? 0,
        fare: int.tryParse(r[4]) ?? 30,
      );
    }
  }

  Future<void> _createTrip(BuildContext context) async {
    final db = FirebaseFirestore.instance;
    final buses =
        await db.collection('buses').where('isActive', isEqualTo: true).get();
    final routes =
        await db.collection('routes').where('isActive', isEqualTo: true).get();
    final drivers = await db
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .where('status', isEqualTo: 'active')
        .get();
    if (!context.mounted) return;
    if (buses.docs.isEmpty || routes.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a bus and a route first')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _TripDialog(
        buses: buses.docs,
        routes: routes.docs,
        drivers: drivers.docs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Setup: buses, routes, trips')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header('Drivers waiting for approval'),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('users')
                .where('role', isEqualTo: 'driver')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, s) {
              final docs = s.data?.docs ?? [];
              if (docs.isEmpty) return const Text('No pending drivers');
              return Column(
                children: [
                  for (final d in docs)
                    ListTile(
                      title: Text(_s(d['name'])),
                      subtitle: Text(_s(d['email'])),
                      trailing: FilledButton(
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(90, 40)),
                        onPressed: () => AdminService().approveUser(d.id),
                        child: const Text('Approve'),
                      ),
                    ),
                ],
              );
            },
          ),
          _header('Buses'),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection('buses').snapshots(),
            builder: (context, s) {
              final docs = s.data?.docs ?? [];
              return Column(
                children: [
                  for (final d in docs)
                    ListTile(
                      leading: const Icon(Icons.directions_bus),
                      title: Text('Bus ${_s(d['busNumber'])}'),
                      subtitle: Text('${_s(d['totalSeats'])} seats'),
                    ),
                ],
              );
            },
          ),
          OutlinedButton.icon(
            onPressed: () => _addBus(context),
            icon: const Icon(Icons.add),
            label: const Text('Add bus'),
          ),
          _header('Routes'),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection('routes').snapshots(),
            builder: (context, s) {
              final docs = s.data?.docs ?? [];
              return Column(
                children: [
                  for (final d in docs)
                    ListTile(
                      leading: const Icon(Icons.route),
                      title: Text(_s(d['name'])),
                      subtitle: Text(
                          '${_s(d['startPoint'])} to ${_s(d['endPoint'])} - ${_s(d['distanceKm'])} km - Rs ${_s(d['fare'])}'),
                    ),
                ],
              );
            },
          ),
          OutlinedButton.icon(
            onPressed: () => _addRoute(context),
            icon: const Icon(Icons.add),
            label: const Text('Add route'),
          ),
          _header('Trips'),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('trips')
                .orderBy('date', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, s) {
              final docs = s.data?.docs ?? [];
              return Column(
                children: [
                  for (final d in docs)
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(_s(d['routeName'])),
                      subtitle: Text(
                          '${_s(d['date'])} ${_s(d['departureTime'])} - Bus ${_s(d['busNumber'])} - ${_s(d['status'])}'),
                    ),
                ],
              );
            },
          ),
          OutlinedButton.icon(
            onPressed: () => _createTrip(context),
            icon: const Icon(Icons.add),
            label: const Text('Create trip'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _TripDialog extends StatefulWidget {
  final List<Doc> buses;
  final List<Doc> routes;
  final List<Doc> drivers;
  const _TripDialog(
      {required this.buses, required this.routes, required this.drivers});

  @override
  State<_TripDialog> createState() => _TripDialogState();
}

class _TripDialogState extends State<_TripDialog> {
  Doc? _bus;
  Doc? _route;
  Doc? _driver;
  DateTime _date = DateTime.now();
  final _time = TextEditingController(text: '07:45');
  bool _busy = false;

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    final msg = ScaffoldMessenger.of(context);
    try {
      await AdminService().createTrip(
        busId: _bus!.id,
        busNumber: _s(_bus!['busNumber']),
        totalSeats: (_bus!['totalSeats'] ?? 48) as int,
        routeId: _route!.id,
        routeName: _s(_route!['name']),
        driverId: _driver?.id,
        driverName: _driver == null ? null : _s(_driver!['name']),
        date: _dateStr,
        departureTime: _time.text.trim(),
      );
      nav.pop();
      msg.showSnackBar(
          const SnackBar(content: Text('Trip created with all seats')));
    } catch (e) {
      msg.showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create trip'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Doc>(
              initialValue: _bus,
              hint: const Text('Bus'),
              items: [
                for (final b in widget.buses)
                  DropdownMenuItem(
                      value: b, child: Text('Bus ${_s(b['busNumber'])}')),
              ],
              onChanged: (v) => setState(() => _bus = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Doc>(
              initialValue: _route,
              isExpanded: true,
              hint: const Text('Route'),
              items: [
                for (final r in widget.routes)
                  DropdownMenuItem(value: r, child: Text(_s(r['name']))),
              ],
              onChanged: (v) => setState(() => _route = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Doc>(
              initialValue: _driver,
              isExpanded: true,
              hint: const Text('Driver (optional)'),
              items: [
                for (final d in widget.drivers)
                  DropdownMenuItem(value: d, child: Text(_s(d['name']))),
              ],
              onChanged: (v) => setState(() => _driver = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: $_dateStr'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            TextField(
              controller: _time,
              decoration:
                  const InputDecoration(labelText: 'Departure time (07:45)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
          onPressed: (_busy || _bus == null || _route == null) ? null : _save,
          child: const Text('Create'),
        ),
      ],
    );
  }
}