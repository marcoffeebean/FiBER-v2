import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/data_service.dart';
import 'widgets/fish_background.dart';
import 'screens/front_page.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/firestore_test.dart';
import 'screens/admin_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FiBER());
}

class FiBER extends StatelessWidget {
  const FiBER({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: DataService.fontFamilyNotifier,
      builder: (context, selectedFont, _) {
        return ValueListenableBuilder<double>(
          valueListenable: DataService.fontSizeNotifier,
          builder: (context, fontSize, _) {
            final lightTheme = ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
              // Transparent so the shared FishBackground shows through.
              scaffoldBackgroundColor: Colors.transparent,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              drawerTheme: const DrawerThemeData(
                backgroundColor: Color(0xFFE6FAFF),
              ),
              cardColor: Colors.white,
              dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
              fontFamily: selectedFont,
              textTheme: ThemeData.light().textTheme.apply(
                fontFamily: selectedFont,
              ),
            );

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Fisheries Board Exam Reviewer',
              themeMode: ThemeMode.light,
              theme: lightTheme,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(fontSize / 14),
                  ),
                  child: FishBackground(
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              initialRoute: '/',
              routes: {
                '/': (context) => FrontPage(),
                '/login': (context) => LoginScreen(),
                '/signup': (context) => SignupScreen(),
                '/teacher': (context) => TeacherDashboard(),
                '/student': (context) => StudentHome(),
                '/firestore_test': (context) => const FirestoreTest(),
                '/admin': (context) => const AdminPanel(),
              },
            );
          },
        );
      },
    );
  }
}
