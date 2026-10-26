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
import 'quiz.dart';
import 'system_settings.dart';
import 'about_us.dart';
import 'word_hunt_game.dart';
import 'dart:async';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  Timer? _uiRefreshTimer;
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
    // Study time is tracked by DataService timer started at login
    // We only refresh UI every 60 seconds to show updated time
    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
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
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
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
      drawer: _buildDrawer(theme),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade50,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.7,
                child: Image.asset(
                  'lib/assets/images/Minimalist Blue Fish Pattern.png',
                  fit: BoxFit.cover,
                  color: Colors.lightBlue.shade200,
                  colorBlendMode: BlendMode.modulate,
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Student Dashboard',
                    style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ) ??
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Continue your learning journey',
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ) ??
                        TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  // ── Stats Row ──────────────────────────────────────
                  _buildStatsRow(theme),
                  const SizedBox(height: 24),

                  // ── Performance Pie Chart ──────────────────────────
                  _buildPerformanceChart(theme),
                  const SizedBox(height: 24),

                  // ── Feature Cards ──────────────────────────────────
                  Text(
                    'Learning Tools',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ) ??
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    title: 'Flashcards',
                    subtitle: 'Review your flashcards and master key concepts',
                    color: Colors.lightBlueAccent,
                    icon: Icons.style,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                    ),
                  ),
                  _FeatureCard(
                    title: 'Mini-Quizzes',
                    subtitle: 'Test your knowledge with mini quizzes',
                    color: const Color(0xFF001F3F),
                    icon: Icons.quiz,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MiniQuiz()),
                    ),
                  ),
                  _FeatureCard(
                    title: 'Mini Games',
                    subtitle: 'Word hunt game based on module content',
                    color: const Color(0xFF002855),
                    icon: Icons.games,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WordHuntGame()),
                    ),
                  ),
                  _FeatureCard(
                    title: 'Mock Exams',
                    subtitle: 'Take a full-length mock exam',
                    color: Colors.deepPurpleAccent,
                    icon: Icons.assignment,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MockExam()),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Module Library ─────────────────────────────────
                  Text(
                    'Module Library',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ) ??
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ) ??
                                TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          children: modules.map((module) {
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ModuleViewer(module: module),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.menu_book_outlined,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            module.title,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.colorScheme.onSurface,
                                                ) ??
                                                TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.colorScheme.onSurface,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Questions: ${module.questions.length}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ) ??
                                                TextStyle(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 24),

                  // ── My Classes ─────────────────────────────────────
                  Text(
                    'My Classes',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ) ??
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  joinedClasses.isEmpty
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "You don't have any classes yet",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ) ??
                                    TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const JoinClassScreen(),
                                ),
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
                          children: [
                            ...joinedClasses.map((code) {
                              final classRoom = DataService.classes.firstWhere(
                                (c) => c.id.toUpperCase() == code,
                                orElse: () =>
                                    ClassRoom(id: code, name: 'Class $code'),
                              );
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
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
                                            style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: theme.colorScheme.onSurface,
                                                ) ??
                                                TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: theme.colorScheme.onSurface,
                                                ),
                                          ),
                                          Text(
                                            'Code: $code',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ) ??
                                                TextStyle(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.copy,
                                        size: 18,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: code));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Class code copied!'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Join Another Class'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const JoinClassScreen(),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────
  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Quizzes',
            value: DataService.quizzesTaken.toString(),
            icon: Icons.quiz,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            label: 'Games',
            value: DataService.gamesPlayed.toString(),
            icon: Icons.games,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            label: 'Exams',
            value: DataService.examsTaken.toString(),
            icon: Icons.assignment,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            label: 'Study',
            value: DataService.studyTimeFormatted,
            icon: Icons.timer,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  // ── Performance Chart ──────────────────────────────────────────
  Widget _buildPerformanceChart(ThemeData theme) {
    final total =
        DataService.quizzesTaken +
        DataService.examsTaken +
        DataService.gamesPlayed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Overview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          total == 0
              ? Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No activity data yet',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Complete quizzes, exams, and games to see stats',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Simple bar chart using progress indicators
                    _ActivityBar(
                      label: 'Quizzes',
                      value: DataService.quizzesTaken,
                      total: total,
                      color: Colors.blue,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    _ActivityBar(
                      label: 'Mock Exams',
                      value: DataService.examsTaken,
                      total: total,
                      color: Colors.purple,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    _ActivityBar(
                      label: 'Games',
                      value: DataService.gamesPlayed,
                      total: total,
                      color: Colors.green,
                      theme: theme,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────
  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
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
                    child: Icon(
                      Icons.person,
                      color: Colors.lightBlueAccent,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AuthService.currentUser?.name?.isNotEmpty == true
                        ? AuthService.currentUser!.name
                        : 'FiBER Student',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AuthService.currentUser?.email ?? 'Student Portal',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // System Settings
            _DrawerTile(
              icon: Icons.settings_outlined,
              title: 'System Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SystemSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Account Settings
            _DrawerTile(
              icon: Icons.manage_accounts_outlined,
              title: 'Account Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // About Us
            _DrawerTile(
              icon: Icons.info_outline,
              title: 'About Us',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini Stat Card ─────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Activity Bar ───────────────────────────────────────────────────
class _ActivityBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final ThemeData theme;

  const _ActivityBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Feature Card ───────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Drawer Tile ────────────────────────────────────────────────────
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
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              blurRadius: 4,
            ),
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
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
