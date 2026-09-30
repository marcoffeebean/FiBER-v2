import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../models/module_model.dart';
import 'account_settings.dart';
import 'flashcards.dart';
import 'join_class_screen.dart';
import 'mock_exam.dart';
import 'module_viewer.dart';
import 'profile_edit.dart';
import 'quiz.dart';
import 'word_hunt_game.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
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
              DataService.stopStudyTimer();
              DataService.resetStudyTimer();
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
  }

  @override
  void initState() {
    super.initState();
    DataService.moduleUpdateNotifier.addListener(_onModuleUpdated);
    DataService.startStudyTimer();
  }

  @override
  void dispose() {
    DataService.stopStudyTimer();
    DataService.moduleUpdateNotifier.removeListener(_onModuleUpdated);
    super.dispose();
  }

  void _onModuleUpdated() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final modules = DataService.modules;
    final joinedClasses = DataService.joinedClassCodes;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'FiBER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
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
                      child: Icon(Icons.person, color: Colors.lightBlueAccent, size: 30),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'FiBER Student',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Student Portal',
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
              Text('Student Tools', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              _DrawerTile(
                icon: Icons.quiz_outlined,
                title: 'Quiz',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MiniQuiz()),
                  );
                },
              ),
              _DrawerTile(
                icon: Icons.library_books_outlined,
                title: 'Modules',
                onTap: () {
                  Navigator.pop(context);
                  if (modules.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ModuleViewer(module: modules.first),
                      ),
                    );
                  }
                },
              ),
              _DrawerTile(
                icon: Icons.style_outlined,
                title: 'Flashcards',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: DefaultTextStyle(
          style: TextStyle(color: theme.colorScheme.onSurface),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Student Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Continue your learning journey',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatCard(title: 'Quizzes Taken', value: DataService.quizzesTaken.toString()),
                  const SizedBox(height: 12),
                  _StatCard(title: 'Games Played', value: DataService.gamesPlayed.toString()),
                  const SizedBox(height: 12),
                  _StatCard(title: 'Study Time', value: '${DataService.studySeconds} seconds'),
                  const SizedBox(height: 12),
                  _StatCard(title: 'Mock Exams Taken', value: DataService.examsTaken.toString()),
                  const SizedBox(height: 12),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Module Library',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              modules.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No modules available yet.\nWait for your teacher to upload one.',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: modules.map((module) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ModuleViewer(module: module),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.08),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.book, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        module.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${module.questions.length} questions generated',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 24),
              Text(
                'My Classes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              joinedClasses.isEmpty
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "You don't have any classes yet",
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const JoinClassScreen()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Join Class'),
                        ),
                      ],
                    )
                  : Column(
                      children: joinedClasses.map((code) {
                        final classRoom = DataService.classes.firstWhere(
                          (c) => c.id.toUpperCase() == code,
                          orElse: () => ClassRoom(id: code, name: 'Class $code'),
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withOpacity(0.08),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.lightBlueAccent,
                                child: Icon(Icons.class_, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      classRoom.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Code: $code',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy, size: 18, color: theme.colorScheme.onSurface),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Class code copied!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({Key? key, required this.title, required this.value})
    : super(key: key);
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Avg: 0%',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
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
