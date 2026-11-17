import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:material_ui/material_ui.dart';

import 'firebase_options.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    await GoogleSignIn.instance.initialize();
  }
  runApp(const StudentInformationApp());
}

class StudentInformationApp extends StatelessWidget {
  const StudentInformationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return _app(
            themeMode: ThemeMode.light,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return _app(themeMode: ThemeMode.light, home: const LoginPage());
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            final themeMode =
                profileSnapshot.data?.data()?['themeMode'] == 'dark'
                ? ThemeMode.dark
                : ThemeMode.light;
            return _app(themeMode: themeMode, home: const DashboardPage());
          },
        );
      },
    );
  }

  Widget _app({required ThemeMode themeMode, required Widget home}) {
    return MaterialApp(
      title: 'Student Information',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _theme(Brightness.light, const Color(0xFFF4F8F5)),
      darkTheme: _theme(Brightness.dark, const Color(0xFF121914)),
      home: home,
    );
  }

  ThemeData _theme(Brightness brightness, Color surface) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF087A3E),
        brightness: brightness,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? const Color(0xFF075C34)
            : const Color(0xFF087A3E),
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E2922) : Colors.white,
        indicatorColor: isDark
            ? const Color(0xFF28593D)
            : const Color(0xFFDDF2E5),
      ),
      useMaterial3: true,
    );
  }
}
