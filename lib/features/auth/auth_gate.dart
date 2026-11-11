import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartbus/features/admin/admin_home.dart';
import 'package:smartbus/features/auth/login_page.dart';
import 'package:smartbus/features/driver/driver_home.dart';
import 'package:smartbus/features/student/student_home.dart';
import 'package:smartbus/services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = snap.data;
        if (user == null) return const LoginPage();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, s) {
            if (s.hasError) return _Message('Error: ${s.error}');
            if (!s.hasData || !s.data!.exists) return const _Loading();
            final d = s.data!.data()!;
            if (d['status'] == 'blocked') {
              return const _Message('Your account has been blocked.');
            }
            if (d['status'] == 'pending') {
              return const _Message(
                  'Your account is waiting for approval.');
            }
            switch (d['role']) {
              case 'superadmin':
                return const AdminHome();
              case 'driver':
                return const DriverHome();
              default:
                return const StudentHome();
            }
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => AuthService().logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}