import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Screens
import 'screens/Home.dart';
import 'screens/Login.dart';
import 'screens/Register.dart';
import 'screens/Panduan.dart';
import 'screens/Profile.dart';

// Import Layouts (Sesuaikan dengan struktur folder barumu)
import 'layouts/DashboardLayout.dart';
import 'layouts/AdminLayout.dart';

void main() {
  runApp(const SafeTalkApp());
}

class SafeTalkApp extends StatelessWidget {
  const SafeTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeTalk AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        // Route Public
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        // Route App Utama (Warga)
        '/auth_gate': (context) => const AuthGate(),
        '/dashboard': (context) => const DashboardLayout(),
        '/chat': (context) => const DashboardLayout(), // Alias untuk dashboard
        '/panduan': (context) => const PanduanScreen(),
        '/profile': (context) => const ProfileScreen(),
        
        // Route Admin
        '/admin': (context) => const AdminLayout(), // <-- Route baru Admin ditambahkan di sini
      },
    );
  }
}

// --- LOGIKA GUARD ---
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole');

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // --- LOGIKA PERCABANGAN ROLE ---
    if (role == 'admin') {
      // Jika Admin, arahkan ke Panel Admin
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (role == 'warga' || role == null) {
      // Jika Warga (atau mode anonim/belum ada role spesifik), arahkan ke Dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      // Fallback aman
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0055A5),
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}