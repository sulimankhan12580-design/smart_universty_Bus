import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartbus/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _department = TextEditingController();
  final _auth = AuthService();
  bool _isRegister = false;
  bool _busy = false;
  String _role = 'student';

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      _show('Enter your email and a password of at least 6 characters');
      return;
    }
    if (_isRegister && _name.text.trim().isEmpty) {
      _show('Full name likhein');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_isRegister) {
        await _auth.register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          department: _department.text,
          role: _role,
        );
      } else {
        await _auth.login(_email.text, _password.text);
      }
    } on FirebaseAuthException catch (e) {
      _show(e.message ?? e.code);
    } catch (e) {
      _show('$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.directions_bus, size: 64),
                  const SizedBox(height: 8),
                  Text(
                    'Smart Bus',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  if (_isRegister) ...[
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _department,
                      decoration:
                          const InputDecoration(labelText: 'Department'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(
                            value: 'student', child: Text('Student')),
                        DropdownMenuItem(
                            value: 'driver', child: Text('Driver')),
                      ],
                      onChanged: (v) => setState(() => _role = v!),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isRegister ? 'Register' : 'Login'),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _isRegister = !_isRegister),
                    child: Text(_isRegister
                        ? 'Already have an account? Login'
                        : 'Create a new account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}