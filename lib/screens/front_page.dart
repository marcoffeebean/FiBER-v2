import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/alumni_model.dart';
import '../services/data_service.dart';

class FrontPage extends StatefulWidget {
  const FrontPage({super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  late Future<List<AlumniProfile>> _alumniFuture;

  @override
  void initState() {
    super.initState();
    _alumniFuture = DataService.loadAlumniProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/fiberbg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color.fromRGBO(0, 0, 0, 0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FiBER',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 172, 252),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          child: const Text('Log in'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 0, 172, 252),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sign up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        children: [
                          const TextSpan(text: 'Ace Your '),
                          TextSpan(
                            text: 'Fisheries',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                          const TextSpan(text: ' Board Exam'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dive deep into interactive learning with flashcards, mini quizzes, mini games, mock exams and comprehensive analytics. Your journey to exam success starts here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 0, 172, 252),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Start learning now →'),
                ),
              ),

              const SizedBox(height: 28),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: FutureBuilder<List<AlumniProfile>>(
                  future: _alumniFuture,
                  builder: (context, snapshot) {
                    final profiles = snapshot.data ?? DataService.visibleAlumniProfiles;
                    if (profiles.isEmpty) {
                      return const SizedBox(
                        height: 80,
                        child: Center(
                          child: Text(
                            'No alumni profiles available yet.',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Our Successful BFAS Alumni',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Proud graduates who turned their passion for fisheries into meaningful careers and real impact.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                           color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 900
                                ? 3
                                : constraints.maxWidth > 600
                                    ? 2
                                    : 1;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: profiles.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.8,
                              ),
                              itemBuilder: (context, index) {
                                final alumni = profiles[index];
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F8FF),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.lightBlue.shade100,
                                      width: 1,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(31, 108, 170, 0.08),
                                        blurRadius: 12,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 90,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.lightBlue.shade300,
                                                Colors.blue.shade700,
                                              ],
                                            ),
                                          ),
                                          child: alumni.imageUrl.isNotEmpty
                                              ? ClipOval(
                                                  child: Image.network(
                                                    alumni.imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(
                                                      Icons.person,
                                                      size: 42,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  size: 42,
                                                  color: Colors.white,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        alumni.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        alumni.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color.fromARGB(255, 20, 90, 161),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        alumni.company,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (alumni.salary.trim().isNotEmpty)
                                        Text(
                                          alumni.salary,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.lightBlue.shade50,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Batch ${alumni.batchYear}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        alumni.highlight,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}