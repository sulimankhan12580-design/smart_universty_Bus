import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String department,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final isDriver = role == 'driver';
    await _db.collection('users').doc(cred.user!.uid).set({
      'role': isDriver ? 'driver' : 'student',
      'name': name.trim(),
      'email': email.trim(),
      'department': department.trim(),
      'status': isDriver ? 'pending' : 'active',
      'isRegular': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logout() => _auth.signOut();
}