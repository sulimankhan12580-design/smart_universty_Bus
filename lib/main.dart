import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smartbus/features/auth/auth_gate.dart';
import 'package:smartbus/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bus',
      theme: appTheme,
      home: const AuthGate(),
    );
  }
}