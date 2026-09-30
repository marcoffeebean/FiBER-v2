import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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

              const Spacer(),

              
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
                            color: Colors.white, // default color
                          ),
                          children: [
                            TextSpan(text: 'Ace Your '), // default white
                            TextSpan(
                              text: 'Fisheries',
                              style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent), // light blue
                            ),
                            TextSpan(text: ' Board Exam'), // default white
                          ],
                        ),
                      ),
                    SizedBox(height: 12),
                    Text(
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

              const SizedBox(height: 24),

            
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

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}