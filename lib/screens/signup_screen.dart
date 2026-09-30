import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl =
      TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Everyone signs up as student by default
    // Admin promotes users to teacher/admin later
    final user = await AuthService.signUp(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _usernameCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/student');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign up failed. Email may already be in use.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/fiberbg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: const Color.fromARGB(160, 0, 0, 0),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildGlassCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Join FiBER',
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create your account to get started',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            
            const SizedBox(height: 16),
            _buildTextField(
                controller: _nameCtrl, label: 'Full Name'),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _usernameCtrl, label: 'Username'),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _emailCtrl, label: 'Email'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordCtrl,
              label: 'Password',
              hint: 'At least 6 characters',
              isPassword: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordCtrl,
              label: 'Confirm Password',
              isPassword: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : _buildPrimaryButton(),
            const SizedBox(height: 12),
            _buildBottomLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelStyle:
            const TextStyle(color: Colors.lightBlueAccent),
        filled: true,
        fillColor: const Color.fromRGBO(255, 255, 255, 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please enter $label';
        if (label == 'Password' && v.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (label == 'Confirm Password' &&
            v != _passwordCtrl.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightBlueAccent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: _submit,
        child: const Text(
          'Create Account',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBottomLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account?',
            style: TextStyle(color: Colors.white70)),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: const Text('Login here',
              style: TextStyle(color: Colors.lightBlueAccent)),
        ),
      ],
    );
  }
}