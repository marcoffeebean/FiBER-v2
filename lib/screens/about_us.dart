import 'package:flutter/material.dart';

import '../config/about_content.dart';

const _brand = Color(0xFF00BCD4);
const _ink = Color(0xFF0B3C5D);

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _intro(),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Purpose of FiBER',
                  child: const Text(
                    aboutPurposeText,
                    style: TextStyle(fontSize: 16, height: 1.6, color: _ink),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Meet the Team',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SubHeading('Developers'),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final person in aboutDevelopers)
                            _PersonCard(person: person),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SubHeading('Thesis Adviser'),
                      const SizedBox(height: 12),
                      Center(child: _PersonCard(person: aboutAdviser)),
                      const SizedBox(height: 24),
                      const _SubHeading('Technical Critic'),
                      const SizedBox(height: 12),
                      Center(child: _PersonCard(person: aboutCritic)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Institutional Affiliation',
                  child: Column(
                    children: [
                      const _InstitutionImage(),
                      const SizedBox(height: 16),
                      const Text(
                        aboutInstitutionName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        aboutProgramName,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: _ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro() {
    return _sectionCard(
      child: Column(
        children: [
          Image.asset(
            aboutLogoAsset,
            height: 96,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.set_meal, size: 72, color: _brand),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              'About FiBER',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fisheries Board Exam Reviewer App',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _brand),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
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
          if (title != null) ...[
            Semantics(
              header: true,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _SubHeading extends StatelessWidget {
  const _SubHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _brand,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person});

  final AboutPerson person;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.lightBlue.shade100),
      ),
      child: Column(
        children: [
          _Avatar(name: person.name, photoAsset: person.photoAsset),
          const SizedBox(height: 12),
          Text(
            person.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.photoAsset});

  final String name;
  final String? photoAsset;

  @override
  Widget build(BuildContext context) {
    final placeholder = CircleAvatar(
      radius: 48,
      backgroundColor: _brand.withOpacity(0.15),
      child: Text(
        _initials(name),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: _brand,
        ),
      ),
    );

    final path = photoAsset;
    if (path == null) return placeholder;

    return ClipOval(
      child: SizedBox(
        width: 96,
        height: 96,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

class _InstitutionImage extends StatelessWidget {
  const _InstitutionImage();

  @override
  Widget build(BuildContext context) {
    const placeholder = CircleAvatar(
      radius: 40,
      backgroundColor: Color(0xFFF0F8FF),
      child: Icon(Icons.account_balance, size: 36, color: _brand),
    );

    final path = aboutInstitutionAsset;
    if (path == null) return placeholder;

    return Image.asset(
      path,
      height: 96,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
