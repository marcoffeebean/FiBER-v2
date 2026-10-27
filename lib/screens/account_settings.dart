import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/account_service.dart';
import '../services/auth_service.dart';

const _brand = Color(0xFF00BCD4);

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();

  AccountProfile? _profile;
  String? _loadError;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _obscureNew = true;
  bool _obscureCurrent = true;

  // Base64-encoded thumbnail stored on the user's Firestore document.
  String? _photoBase64;
  Uint8List? _pendingAvatar;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _newPasswordCtrl.dispose();
    _currentPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _emailChanged =>
      _profile != null && _emailCtrl.text.trim() != _profile!.email;
  bool get _passwordChanged => _newPasswordCtrl.text.isNotEmpty;
  bool get _needsCurrentPassword => _emailChanged || _passwordChanged;

  Future<void> _load() async {
    try {
      final profile = await AccountService.loadProfile();
      if (!mounted) return;
      _usernameCtrl.text = profile.username;
      _emailCtrl.text = profile.email;
      _newPasswordCtrl.clear();
      _currentPasswordCtrl.clear();
      setState(() {
        _profile = profile;
        _photoBase64 = profile.photoUrl;
        _pendingAvatar = null;
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      debugPrint('Account load error: $e');
      if (!mounted) return;
      setState(() {
        _loadError = e is AccountException
            ? e.message
            : 'Could not load your account. Check your connection.';
        _loading = false;
      });
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    if (_uploadingAvatar || _saving) return;

    XFile? picked;
    Uint8List? bytes;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 70,
      );
      if (picked == null) return; // User cancelled.
      bytes = await picked.readAsBytes();
    } catch (e) {
      debugPrint('Image picker error: $e');
      _snack(
        'Could not open your photos. Check that FiBER has permission to access them.',
        error: true,
      );
      return;
    }

    final previousBase64 = _photoBase64;
    setState(() {
      _pendingAvatar = bytes; // Show the new picture immediately.
      _uploadingAvatar = true;
    });

    try {
      final encoded = await AccountService.uploadAvatar(bytes);
      if (!mounted) return;
      AuthService.updateCachedProfile(photoUrl: encoded);
      setState(() {
        _photoBase64 = encoded;
        _pendingAvatar = null;
      });
      _snack('Profile picture updated.');
    } on AccountException catch (e) {
      if (!mounted) return;
      setState(() {
        _pendingAvatar = null; // Revert to the previous picture.
        _photoBase64 = previousBase64;
      });
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  String? _validateUsername(String? value) {
    final v = (value ?? '').trim();
    if (v.length < 3) return 'Username must be at least 3 characters.';
    if (v.length > 30) return 'Username must be 30 characters or fewer.';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return null; // Optional.
    if (v.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (_needsCurrentPassword && (value ?? '').isEmpty) {
      return 'Enter your current password to make this change.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving || _profile == null) return;
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;
    final usernameChanged = username != _profile!.username;
    final emailChanged = email != _profile!.email;
    final passwordChanged = newPassword.isNotEmpty;

    if (!usernameChanged && !emailChanged && !passwordChanged) {
      _snack('No changes to save.');
      return;
    }

    setState(() => _saving = true);
    try {
      if (usernameChanged) {
        await AccountService.saveUsername(username);
        AuthService.updateCachedProfile(username: username);
      }
      if (emailChanged || passwordChanged) {
        await AccountService.reauthenticate(_currentPasswordCtrl.text);
      }
      if (passwordChanged) {
        await AccountService.changePassword(newPassword);
      }
      if (emailChanged) {
        await AccountService.requestEmailChange(email);
      }

      if (!mounted) return;
      await _load(); // Refresh fields from the saved state.
      if (!mounted) return;
      _snack(
        emailChanged
            ? 'Saved. Check $email and click the link to confirm. '
                  'Your sign-in email changes after you confirm.'
            : 'Changes saved.',
      );
    } on AccountException catch (e) {
      if (mounted) _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: border(Colors.lightBlue.shade100),
      enabledBorder: border(Colors.lightBlue.shade100),
      focusedBorder: border(_brand, 2),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _avatarSection() {
    ImageProvider? image;
    if (_pendingAvatar != null) {
      image = MemoryImage(_pendingAvatar!);
    } else if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(_photoBase64!));
      } catch (_) {
        image = null; // Corrupt data falls back to the default avatar.
      }
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: _brand.withOpacity(0.15),
              backgroundImage: image,
              child: image == null
                  ? const Icon(Icons.person, size: 56, color: _brand)
                  : null,
            ),
            if (_uploadingAvatar) const CircularProgressIndicator(),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: (_uploadingAvatar || _saving) ? null : _pickAvatar,
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Change picture'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _brand,
            side: const BorderSide(color: _brand),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _accountForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _usernameCtrl,
            decoration: _decoration(label: 'Username'),
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateUsername,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: _decoration(label: 'Email'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateEmail,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _newPasswordCtrl,
            obscureText: _obscureNew,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            decoration: _decoration(
              label: 'New password',
              hint: 'Leave blank to keep your current password',
              suffix: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: _obscureNew ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateNewPassword,
            onChanged: (_) => setState(() {}),
          ),
          if (_needsCurrentPassword) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _currentPasswordCtrl,
              obscureText: _obscureCurrent,
              autofillHints: const [AutofillHints.password],
              decoration: _decoration(
                label: 'Current password',
                hint: 'Required to change email or password',
                suffix: IconButton(
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                  ),
                  tooltip: _obscureCurrent ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: _validateCurrentPassword,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError ?? 'Could not load your account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _loadError = null;
                  });
                  _load();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionCard(title: 'Profile picture', child: _avatarSection()),
              const SizedBox(height: 16),
              _sectionCard(title: 'Account information', child: _accountForm()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(),
    );
  }
}
