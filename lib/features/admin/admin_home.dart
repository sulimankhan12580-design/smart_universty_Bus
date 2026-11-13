import 'package:flutter/material.dart';
import 'package:smartbus/features/admin/admin_dashboard_page.dart';
import 'package:smartbus/features/admin/admin_setup_page.dart';
import 'package:smartbus/services/auth_service.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminDashboardPage()),
                ),
                icon: const Icon(Icons.dashboard),
                label: const Text('Dashboard: students, drivers, trips'),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminSetupPage()),
                ),
                icon: const Icon(Icons.settings),
                label: const Text('Setup: buses, routes, trips'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}