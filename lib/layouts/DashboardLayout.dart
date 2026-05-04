import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import screens lu
import '../screens/Chat.dart';
import '../screens/Emergency.dart';
import '../screens/Profile.dart'; // PASTIIN IMPORT PROFILE SCREEN NYA DI SINI

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _currentIndex = 0;
  bool _isLoggedIn = false;

  // Daftar layar yang bakal ganti-gantian muncul di tengah
  // Sekarang kita masukin ProfileScreen di index ke-2
  final List<Widget> _screens = [
    const ChatScreen(),
    const EmergencyScreen(),
    const ProfileScreen(),
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

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;

    if (index == 2 && !_isLoggedIn) {
      // Kalau user belum login dan klik tab Profil/Login, lempar ke halaman Login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Kalau udah login, izinkan pindah ke tab Profile (index 2), Chat (0), atau Darurat (1)
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
            selectedItemColor: const Color(0xFF4F46E5), // indigo-600
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
                icon: _buildIcon(
                  0,
                  LucideIcons.messageSquare,
                  const Color(0xFF4F46E5),
                  const Color(0xFFEEF2FF),
                ),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(
                  1,
                  LucideIcons.phone,
                  const Color(0xFFE11D48),
                  const Color(0xFFFFF1F2),
                ),
                label: 'Darurat',
              ),
              BottomNavigationBarItem(
                // Ikon berubah jadi user kalau udah login, jadi logIn kalau belum
                icon: _buildIcon(
                  2,
                  _isLoggedIn ? LucideIcons.user : LucideIcons.logIn,
                  const Color(0xFF4F46E5),
                  const Color(0xFFEEF2FF),
                ),
                label: _isLoggedIn ? 'Profil' : 'Login',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi helper biar nulis ikonnya lebih rapi
  Widget _buildIcon(
    int index,
    IconData iconData,
    Color activeColor,
    Color activeBg,
  ) {
    bool isSelected = _currentIndex == index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        iconData,
        size: 24,
        color: isSelected ? activeColor : const Color(0xFF9CA3AF),
      ),
    );
  }
}
