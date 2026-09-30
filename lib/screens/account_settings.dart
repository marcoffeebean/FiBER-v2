import 'package:flutter/material.dart';
import '../services/data_service.dart';
import 'change_password.dart';
import 'profile_edit.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsHeader(
            title: 'Profile',
            subtitle: 'Manage your account information',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'Edit your name, bio, and profile details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
          ),
          const SizedBox(height: 18),
          _SettingsHeader(
            title: 'Settings',
            subtitle: 'Customize your app experience',
            icon: Icons.tune,
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.manage_accounts,
            title: 'Account Settings',
            subtitle: 'Update account preferences and security',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your password securely',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.brightness_6_outlined,
            title: 'Theme Settings',
            subtitle: 'Light / Dark mode',
            trailing: _ThemeModeChip(),
            onTap: () {
              _showThemeDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        final currentTheme = DataService.themeMode;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Theme Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                value: ThemeMode.system,
                groupValue: currentTheme,
                onChanged: (value) {
                  if (value != null) {
                    DataService.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: currentTheme,
                onChanged: (value) {
                  if (value != null) {
                    DataService.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: currentTheme,
                onChanged: (value) {
                  if (value != null) {
                    DataService.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SettingsHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.lightBlueAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.lightBlueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  const _ThemeModeChip();

  @override
  Widget build(BuildContext context) {
    final mode = DataService.themeMode;
    String label = 'System';
    if (mode == ThemeMode.light) label = 'Light';
    if (mode == ThemeMode.dark) label = 'Dark';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.lightBlueAccent,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}