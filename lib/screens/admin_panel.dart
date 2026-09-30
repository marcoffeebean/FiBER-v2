import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'account_settings.dart';
import 'profile_edit.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedTab = 0;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;

  final _editFormKey = GlobalKey<FormState>();
  late TextEditingController _emailCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _nameCtrl = TextEditingController();
    _usernameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    final users = await AuthService.getAllUsersAsync();
    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoadingUsers = false;
    });
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final id = user['id'];
    if (id == null || id.toString().isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user['email'] ?? 'this user'} from Firebase?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService.deleteUser(id.toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User deleted.')),
    );
    await _loadUsers();
  }

  Future<void> _showUserEditDialog(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final initialRole = (user['role'] ?? 'student').toString();

    _emailCtrl.text = (user['email'] ?? '').toString();
    _nameCtrl.text = (user['name'] ?? '').toString();
    _usernameCtrl.text = (user['username'] ?? '').toString();
    _passwordCtrl.clear();

    String selectedRole = initialRole;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Form(
          key: _editFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'New Password (optional)'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: ['student', 'teacher', 'admin'].contains(selectedRole.toLowerCase())
                      ? selectedRole.toLowerCase()
                      : 'student',
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    if (value != null) selectedRole = value;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final email = _emailCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final success = await AuthService.editUser(
      id: userId,
      newEmail: email.isNotEmpty ? email : null,
      newName: name.isNotEmpty ? name : null,
      newUsername: username.isNotEmpty ? username : null,
      newRole: selectedRole,
      newPassword: password.isNotEmpty && userId == AuthService.currentUser?.id ? password : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated.')),
      );
      await _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user.')),
      );
    }
  }

  void _showThemePicker(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Admin Panel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Logout Confirmation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await AuthService.logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              _tabButton('System Logs', 0),
              _tabButton('App Content', 1),
              _tabButton('User Accounts', 2),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: theme.drawerTheme.backgroundColor ?? theme.colorScheme.surface,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.lightBlueAccent, Color(0xFF0288D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.admin_panel_settings, color: Colors.lightBlueAccent, size: 30),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'FiBER Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Administrator Portal',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              _DrawerTile(
                icon: Icons.person_outline,
                title: 'Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),
              Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              _DrawerTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                  );
                },
              ),
              _DrawerTile(
                icon: Icons.manage_accounts_outlined,
                title: 'Account Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                  );
                },
              ),
              _DrawerTile(
                icon: Icons.brightness_6_outlined,
                title: 'Theme Settings',
                onTap: () {
                  Navigator.pop(context);
                  _showThemePicker(context);
                },
              ),
              const Divider(height: 28),
              Text('Admin Tools', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              _DrawerTile(
                icon: Icons.list_alt_outlined,
                title: 'System Logs',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedTab = 0);
                },
              ),
              _DrawerTile(
                icon: Icons.storage_outlined,
                title: 'App Content',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedTab = 1);
                },
              ),
              _DrawerTile(
                icon: Icons.people_alt_outlined,
                title: 'User Accounts',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedTab = 2);
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: DefaultTextStyle(
          style: TextStyle(color: theme.colorScheme.onSurface),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'System Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _selectedTab == 0
                      ? _buildSystemLogs()
                      : _selectedTab == 1
                          ? _buildAppContent()
                          : _buildUserAccounts(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _selectedTab == index;
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.lightBlueAccent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.lightBlueAccent : theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ── System Logs ────────────────────────────────────────────────
  Widget _buildSystemLogs() {
    final logs = DataService.systemLogs;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Logs',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
              ),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                onPressed: () => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      'No logs yet.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (_, i) {
                      final log = logs[logs.length - 1 - i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── App Content (Modules) ──────────────────────────────────────
  Widget _buildAppContent() {
    final modules = DataService.modules;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Uploaded Modules',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: modules.isEmpty
                ? Center(
                    child: Text(
                      'No modules uploaded yet.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: modules.length,
                    itemBuilder: (_, i) {
                      final module = modules[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.book),
                          title: Text(module.title),
                          subtitle: Text(
                            module.content.length > 60
                                ? '${module.content.substring(0, 60)}...'
                                : module.content,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAccounts() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Accounts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh users',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          'No users found in Firebase.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (_, index) {
                          final user = _users[index];
                          final email = (user['email'] ?? '').toString();
                          final name = (user['name'] ?? '').toString();
                          final username = (user['username'] ?? '').toString();
                          final role = (user['role'] ?? 'student').toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.lightBlueAccent,
                                child: Text(
                                  (name.isNotEmpty ? name[0] : email.isNotEmpty ? email[0] : 'U').toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(name.isNotEmpty ? name : username.isNotEmpty ? username : email),
                              subtitle: Text(
                                '$email\nRole: ${role.toUpperCase()}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit user',
                                    onPressed: () => _showUserEditDialog(user),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete user',
                                    onPressed: () => _deleteUser(user),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 4),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
