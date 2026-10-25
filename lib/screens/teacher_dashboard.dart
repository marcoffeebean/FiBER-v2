import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/module_model.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'account_settings.dart';
import 'class_management.dart';
import 'module_viewer.dart';
import 'system_settings.dart';
import 'about_us.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  bool _isUploading = false;
  String? _lastUploadedFileName;

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadModule() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'pptx', 'ppt'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileName = file.name;
    final fileBytes = file.bytes;
    final filePath = file.path;

    setState(() => _isUploading = true);

    try {
      final title = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
      await DataService.uploadModuleFile(
        title: title,
        fileName: fileName,
        bytes: fileBytes,
        filePath: filePath,
      );
      setState(() {
        _lastUploadedFileName = fileName;
        _isUploading = false;
      });
      DataService.notifyModuleUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ "$title" uploaded successfully!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('❌ Upload failed: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _confirmDeleteModule(Module module) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Module'),
        content: Text('Are you sure you want to delete "${module.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              DataService.deleteModule(DataService.modules.indexOf(module));
              Navigator.pop(context);
              setState(() {});
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        title: Text('FiBER',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor:
            theme.drawerTheme.backgroundColor ?? theme.colorScheme.surface,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          color: Colors.lightBlueAccent, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AuthService.currentUser?.name?.isNotEmpty == true
                          ? AuthService.currentUser!.name
                          : 'FiBER Teacher',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      AuthService.currentUser?.email ?? 'Teacher Portal',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _DrawerTile(
                icon: Icons.settings_outlined,
                title: 'System Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SystemSettingsScreen()));
                },
              ),
              const SizedBox(height: 8),
              _DrawerTile(
                icon: Icons.manage_accounts_outlined,
                title: 'Account Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AccountSettingsScreen()));
                },
              ),
              const SizedBox(height: 8),
              _DrawerTile(
                icon: Icons.info_outline,
                title: 'About Us',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AboutUsScreen()));
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Teacher Dashboard',
                  style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      )),
              const SizedBox(height: 12),

              // Class Management
              Text('Manage Classes',
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      )),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.class_),
                label: const Text('Go to Class Management'),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ClassManagement())),
              ),

              const SizedBox(height: 28),
              const Divider(),

              // Upload Module
              Text('Upload Module',
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      )),
              const SizedBox(height: 4),
              Text(
                'Upload a PDF, Word, or TXT file. Mock exams, quizzes, and mini games will automatically update.',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ) ??
                    TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              _isUploading
                  ? Center(
                      child: Column(children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text('Uploading module...',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface)),
                    ]))
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Choose & Upload Module'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white),
                      onPressed: _pickAndUploadModule,
                    ),
              if (_lastUploadedFileName != null) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text('Last uploaded: $_lastUploadedFileName',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ) ??
                              const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500))),
                ]),
              ],

              const SizedBox(height: 28),
              const Divider(),

              // Uploaded Modules
              Text('Uploaded Modules',
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      )),
              const SizedBox(height: 8),
              ...DataService.modules.map((m) {
                return Card(
                  color: theme.colorScheme.surface,
                  child: ListTile(
                    leading: Icon(Icons.book,
                        color: theme.colorScheme.primary),
                    title: Text(m.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ) ??
                            TextStyle(color: theme.colorScheme.onSurface)),
                    subtitle: Text(
                      m.content.length > 60
                          ? '${m.content.substring(0, 60)}...'
                          : m.content,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ) ??
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.visibility,
                              color: theme.colorScheme.primary),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ModuleViewer(module: m))),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () => _confirmDeleteModule(m),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 4)
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ) ??
                        TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ))),
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}