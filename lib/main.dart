import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/data_service.dart';
import 'screens/front_page.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/firestore_test.dart';
import 'screens/admin_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FiBER());
}

class FiBER extends StatelessWidget {
  const FiBER({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: DataService.themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: DataService.fontFamilyNotifier,
          builder: (context, selectedFont, _) {
            return ValueListenableBuilder<double>(
              valueListenable: DataService.fontSizeNotifier,
              builder: (context, fontSize, _) {
                final lightTheme = ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                  useMaterial3: true,
                  scaffoldBackgroundColor: const Color(0xFFE6FAFF),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                  drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFFE6FAFF)),
                  cardColor: Colors.white,
                  dialogTheme: const DialogThemeData(
                    backgroundColor: Colors.white,
                  ),
                  fontFamily: selectedFont,
                  textTheme: ThemeData.light().textTheme.apply(
                    fontFamily: selectedFont,
                  ),
                );

                final darkTheme = ThemeData(
                  brightness: Brightness.dark,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Brightness.dark,
                  ),
                  useMaterial3: true,
                  scaffoldBackgroundColor: const Color(0xFF101828),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF1F2937),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF111827)),
                  cardColor: const Color(0xFF1F2937),
                  dialogTheme: const DialogThemeData(
                    backgroundColor: Color(0xFF1F2937),
                  ),
                  fontFamily: selectedFont,
                  textTheme: ThemeData.dark().textTheme.apply(
                    fontFamily: selectedFont,
                  ),
                );

                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Fisheries Board Exam Reviewer',
                  themeMode: themeMode,
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  builder: (context, child) {
                    final mediaQuery = MediaQuery.of(context);
                    return MediaQuery(
                      data: mediaQuery.copyWith(
                        textScaler: TextScaler.linear(fontSize / 14),
                      ),
                      child: child ?? const SizedBox.shrink(),
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
      },
    );
  }
}