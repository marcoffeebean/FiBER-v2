import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/alumni_model.dart';
import '../services/data_service.dart';
import '../widgets/alumni_avatar.dart';

const _brandBlue = Color(0xFF00ACFC);
const _deepBlue = Color(0xFF145AA1);

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
              _buildHeader(),
              const SizedBox(height: 40),
              _buildHero(),
              const SizedBox(height: 28),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Start learning now →'),
                ),
              ),
              const SizedBox(height: 28),
              _buildAlumniSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'FiBER',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _brandBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
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
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAlumniSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: FutureBuilder<List<AlumniProfile>>(
        future: _alumniFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final profiles =
              (snapshot.data ?? const <AlumniProfile>[])
                  .where((a) => a.isVisible)
                  .toList()
                ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

          return Column(
            children: [
              _buildSectionTitle(),
              const SizedBox(height: 24),
              if (profiles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No alumni profiles available yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: profiles
                      .map((alumni) => _AlumniCard(alumni: alumni))
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Column(
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
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            color: _brandBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Proud graduates who turned their passion for fisheries into meaningful careers and real impact.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }
}

class _AlumniCard extends StatelessWidget {
  final AlumniProfile alumni;

  const _AlumniCard({required this.alumni});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          alumniAvatar(alumni.imageUrl, size: 96),
          const SizedBox(height: 16),
          Text(
            alumni.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (alumni.title.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              alumni.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _deepBlue,
              ),
            ),
          ],
          if (alumni.company.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              alumni.company,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          if (alumni.batchYear.isNotEmpty) ...[
            const SizedBox(height: 10),
            _pill('Batch ${alumni.batchYear}'),
          ],
          if (alumni.salary.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _pill(alumni.salary.trim(), bold: true),
          ],
          if (alumni.highlight.trim().isNotEmpty) ...[
            const Divider(height: 28),
            const Icon(Icons.format_quote, color: _brandBlue, size: 22),
            const SizedBox(height: 4),
            Text(
              alumni.highlight,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black87,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String text, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: _deepBlue,
        ),
      ),
    );
  }
}
