import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  void _changePassword() {
    final user = AuthService.currentUser;
    if (user == null) return;

    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    AuthService.updatePassword(_newPasswordCtrl.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated')),
    );

    _newPasswordCtrl.clear();
    _confirmPasswordCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _confirmPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}