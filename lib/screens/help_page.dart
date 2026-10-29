import 'package:flutter/material.dart';

const _brand = Color(0xFF00BCD4);
const _ink = Color(0xFF0B3C5D);

class HelpStep {
  const HelpStep({required this.title, required this.body});

  final String title;
  final String body;
}

const studentHelpSteps = <HelpStep>[
  HelpStep(
    title: 'Explore Learning Features',
    body:
        'Explore the learning modules, take mini quizzes and mock '
        'exams, and track your performance analytics to identify areas for '
        'improvement.',
  ),
  HelpStep(
    title: 'Join a Class',
    body:
        "For students, join your teacher's class by entering the class code "
        'provided by your teacher.',
  ),
  HelpStep(
    title: 'Take a Study Break',
    body:
        'For a short study break, play the available mini games to relax and '
        'refresh your mind.',
  ),
  HelpStep(
    title: 'Create Flashcards',
    body:
        'Create your own flashcards for self studying and memorizing '
        'some hard terms.',
  ),
];

const teacherHelpSteps = <HelpStep>[
  HelpStep(
    title: 'Uploading Module',
    body:
        'Upload a module such as pdf, docx, and pptx for the students to start '
        'their reviewing session.',
  ),
  HelpStep(
    title: 'Create a Class',
    body:
        'Create a class and share the class code with students so they can join '
        "there. Monitor the student's performance with their performance stats.",
  ),
];

class HelpPage extends StatelessWidget {
  const HelpPage({super.key, this.isTeacher = false});

  final bool isTeacher;

  @override
  Widget build(BuildContext context) {
    final steps = isTeacher ? teacherHelpSteps : studentHelpSteps;
    final pageTitle = isTeacher
        ? 'Teacher Help & App Manual'
        : 'Student Help & App Manual';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionCard(
                  title: 'How to Use FiBER',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This manual helps you understand how to navigate FiBER, '
                        'access learning tools, and use the app effectively.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (var i = 0; i < steps.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _StepTile(number: i + 1, step: steps[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.step});

  final int number;
  final HelpStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _brand,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
