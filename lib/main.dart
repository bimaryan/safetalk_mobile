import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Screens & Layouts sesuai struktur lu
import 'screens/Home.dart';
import 'screens/Login.dart';
import 'screens/Register.dart';
import 'screens/Panduan.dart';
import 'screens/Profile.dart';
import 'layouts/DashboardLayout.dart';

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

        // Route yang dibungkus Guard 
        '/auth_gate': (context) => const AuthGate(),
        '/dashboard': (context) => const DashboardLayout(),
        '/panduan': (context) => const PanduanScreen(),
        '/chat': (context) => const DashboardLayout(),
        
        // --- TAMBAHKAN ROUTE PROFIL DI SINI ---
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// --- LOGIKA GUARD (Setara ChatGuard di React) ---
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

    // Beri sedikit jeda biar UI nggak lompat (opsional)
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Izinkan masuk JIKA role adalah "warga" (sudah login) ATAU null/tidak ada (anonim)
    if (role == 'warga' || role == null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
    // Tolak JIKA role adalah "admin"
    else if (role == 'admin') {
      // Sementara lempar ke '/' karena admin screen belum ada.
      // Nanti ganti jadi: Navigator.pushReplacementNamed(context, '/admin');
      Navigator.pushReplacementNamed(context, '/');
    } else {
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
