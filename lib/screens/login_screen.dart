import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = await AuthService.login(
      _emailCtrl.text,
      _passwordCtrl.text,
    );

    setState(() => _isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email, password, or role.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (user.role == UserRole.admin) {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (user.role == UserRole.teacher) {
      Navigator.pushReplacementNamed(context, '/teacher');
    } else {
      Navigator.pushReplacementNamed(context, '/student');
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
          color: Colors.black.withAlpha(140),
          child: SafeArea(
            child: Column(
              children: [
                // ── Back button ─────────────────────────────────
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.lightBlueAccent),
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/'),
                      tooltip: 'Back to Home',
                    ),
                  ),
                ),

                // ── Form ────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildGlassCard(),
                    ),
                  ),
                ),
              ],
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
              'Welcome Back to FiBER',
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildTextField(controller: _emailCtrl, label: 'Email'),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _passwordCtrl,
                label: 'Password',
                isPassword: true),
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
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
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
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Please enter $label' : null,
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
        child: const Text('Login',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildBottomLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('No account yet?',
            style: TextStyle(color: Colors.white70)),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/signup'),
          child: const Text('Sign up',
              style: TextStyle(color: Colors.lightBlueAccent)),
        ),
      ],
    );
  }
}