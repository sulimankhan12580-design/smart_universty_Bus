import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF00A251),
        useMaterial3: true,
      ),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final testRef = FirebaseFirestore.instance.collection('test');
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Bus')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: testRef.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Text('Error: ${snap.error}');
                if (!snap.hasData) return const Text('Connecting...');
                return Text(
                  'Live documents: ${snap.data!.docs.length}',
                  style: const TextStyle(fontSize: 24),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                testRef.add({
                  'msg': 'hello',
                  'time': FieldValue.serverTimestamp(),
                });
              },
              child: const Text('Add test document'),
            ),
          ],
        ),
      ),
    );
  }
}