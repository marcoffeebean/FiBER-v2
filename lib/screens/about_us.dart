import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        title: Text('About Us',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App logo / title
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.lightBlueAccent, Color(0xFF0288D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.school, color: Colors.white, size: 56),
                  SizedBox(height: 12),
                  Text('FiBER',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  Text('Fisheries Board Exam Reviewer',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // About section
          _AboutCard(
            theme: theme,
            title: 'About FiBER',
            content:
                'FiBER is a mobile application designed to help students prepare for the Fisheries Board Examination. It provides interactive study tools including flashcards, mini-quizzes, mock exams, and word hunt games — all powered by teacher-uploaded modules.',
          ),
          const SizedBox(height: 16),

          // Developers section
          _AboutCard(
            theme: theme,
            title: 'The Developers',
            content:
                'FiBER was developed by a team of Information Technology students as their capstone project. The team is dedicated to providing an effective and engaging review platform for future Fisheries professionals.',
          ),
          const SizedBox(height: 16),

          // Version
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Version',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface)),
                Text('1.0.0',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2025 FiBER Development Team',
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String content;

  const _AboutCard(
      {required this.theme, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: theme.shadowColor.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(content,
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5)),
        ],
      ),
    );
  }
}