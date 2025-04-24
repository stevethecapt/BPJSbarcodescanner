import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/splash_page.dart';
import 'pages/login.dart';
import 'pages/register.dart';
import 'pages/home.dart';
import 'pages/input.dart';
import 'pages/search.dart';
import 'pages/scan.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BPJS Barcode Scanner',
      theme: ThemeData(
        primarySwatch: const MaterialColor(0xFFC0C0C0, <int, Color>{
          50: Color(0xFFF5F5F5),
          100: Color(0xFFE0E0E0),
          200: Color(0xFFCCCCCC),
          300: Color(0xFFB8B8B8),
          400: Color(0xFFA3A3A3),
          500: Color(0xFFC0C0C0),
          600: Color(0xFF8F8F8F),
          700: Color(0xFF7A7A7A),
          800: Color(0xFF666666),
          900: Color(0xFF525252),
        }),
      ),
      home: const SplashWrapper(),
      routes: {
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/scan': (context) => const ScanBarcodePage(),
        '/search': (context) => const SearchPage(),
        '/input': (context) => const InputDataPage(),
      },
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    bool isLoggedIn = await checkIfLoggedIn();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const SplashPage();
  }
}

Future<bool> checkIfLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final lastLogin = prefs.getString('lastLogin');

  if (lastLogin == null) return false;

  final loginDate = DateTime.tryParse(lastLogin);
  if (loginDate == null) return false;

  final now = DateTime.now();
  final daysSinceLogin = now.difference(loginDate).inDays;
  if (daysSinceLogin > 30) {
    await FirebaseAuth.instance.signOut();
    await prefs.remove('lastLogin');
    return false;
  }

  User? user = FirebaseAuth.instance.currentUser;
  return user != null;
}
