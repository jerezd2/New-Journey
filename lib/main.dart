import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_app/theme/app_theme.dart';

import 'package:supabase_app/screens/auth_screen.dart';
import 'package:supabase_app/screens/main_nav_screen.dart';
import 'package:supabase_app/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ngwcklhjohvfuqnzlgtq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nd2NrbGhqb2h2ZnVxbnpsZ3RxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMzY0NjUsImV4cCI6MjA4NTgxMjQ2NX0.ERh11EkWrQ3xW1_hhT5PQV8ahYD2yPqWN3-TayoV_u8',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'New Journey',
      theme: AppTheme.lightTheme,
      home: const SplashWrapper(),
    );
  }
}

class SplashWrapper extends StatelessWidget {
  const SplashWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreenNext();
  }
}

class SplashScreenNext extends StatefulWidget {
  const SplashScreenNext({super.key});

  @override
  State<SplashScreenNext> createState() => _SplashScreenNextState();
}

class _SplashScreenNextState extends State<SplashScreenNext> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 400,
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    return session == null ? const AuthScreen() : const MainNavScreen();
  }
}