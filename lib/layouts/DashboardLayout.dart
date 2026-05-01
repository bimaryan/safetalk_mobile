import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Import screens lu
import '../screens/Chat.dart';
import '../screens/Emergency.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _currentIndex = 0;
  bool _isLoggedIn = false;
  bool _isLoggingOut = false;

  // Daftar layar yang bakal ganti-gantian muncul di tengah
  final List<Widget> _screens = [
    const ChatScreen(),
    const EmergencyScreen(),
    const Center(child: CircularProgressIndicator()),
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('safetalk_token');
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
      });
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    // Dialog Konfirmasi Keluar
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Keluar Akun?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444), // rose-500
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Ya, Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('safetalk_token');

    try {
      // 1. Tembak API Logout di Laravel
      if (token != null) {
        await http.post(
          Uri.parse('https://backend.safetalkai.my.id/api/auth/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      debugPrint("Gagal hit API Logout: $e");
    } finally {
      // 2. Hapus token di penyimpanan lokal
      await prefs.remove('safetalk_token');
      await prefs.remove('safetalk_role');
      await prefs.remove('safetalk_session');

      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda telah berhasil keluar.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Arahkan ke halaman login
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex && index != 2) return;

    if (index == 2) {
      // Kalau tab ke-3 (Login/Logout) diklik
      if (_isLoggedIn) {
        _handleLogout();
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // Kalau tab Chat atau Darurat diklik
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack bikin state aplikasi nggak kereset pas pindah tab
      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            // Warna font pas dipilih, kalau index 2 (Logout) ga usah dikasih warna aktif
            selectedItemColor: _currentIndex == 2 && _isLoggedIn
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF4F46E5), // indigo-600
            unselectedItemColor: const Color(0xFF9CA3AF), // gray-400
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _currentIndex == 0
                        ? const Color(0xFFEEF2FF) // indigo-50
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    LucideIcons.messageSquare,
                    size: 24,
                    color: _currentIndex == 0
                        ? const Color(0xFF4F46E5) // indigo-600
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _currentIndex == 1
                        ? const Color(0xFFFFF1F2) // rose-50
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    LucideIcons.phone,
                    size: 24,
                    color: _currentIndex == 1
                        ? const Color(0xFFE11D48) // rose-600
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                label: 'Darurat',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    // Hover effect untuk login (index 2) kalau belum login
                    color: _currentIndex == 2 && !_isLoggedIn
                        ? const Color(0xFFEEF2FF) // indigo-50
                        : Colors.transparent, // Polos kalau udah login
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isLoggingOut
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: Padding(
                            padding: EdgeInsets.all(4.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFFE11D48), // rose-600
                            ),
                          ),
                        )
                      : Icon(
                          _isLoggedIn ? LucideIcons.logOut : LucideIcons.logIn,
                          size: 24,
                          color: _currentIndex == 2 && !_isLoggedIn
                              ? const Color(0xFF4F46E5) // indigo-600
                              : const Color(0xFF9CA3AF),
                        ),
                ),
                label: _isLoggingOut
                    ? 'Keluar...'
                    : (_isLoggedIn ? 'Keluar' : 'Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
