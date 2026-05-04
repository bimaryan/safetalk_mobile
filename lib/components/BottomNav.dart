import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;

  /// Callback saat item diklik. Kalau null, pakai Navigator bawaan.
  final void Function(int)? onTap;

  /// Override status login dari luar. Kalau null, dicek sendiri dari SharedPreferences.
  final bool? isLoggedIn;

  /// Tampilkan loading spinner di tab ke-3 saat proses logout.
  final bool isLoggingOut;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.isLoggedIn,
    this.isLoggingOut = false,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn == null) {
      _checkLoginStatus();
    } else {
      _isLoggedIn = widget.isLoggedIn!;
    }
  }

  @override
  void didUpdateWidget(CustomBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn != null) {
      _isLoggedIn = widget.isLoggedIn!;
    }
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

  void _onItemTapped(BuildContext context, int index) {
    // Kalau ada onTap dari luar, delegasi ke sana
    if (widget.onTap != null) {
      widget.onTap!(index);
      return;
    }

    // Fallback: navigasi default pakai named routes
    if (index == widget.currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/emergency');
        break;
      case 2:
        if (_isLoggedIn) {
          Navigator.pushReplacementNamed(context, '/profile');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = widget.isLoggedIn ?? _isLoggedIn;
    final bool isLoggingOut = widget.isLoggingOut;

    return Container(
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
          currentIndex: widget.currentIndex > 2 ? 0 : widget.currentIndex,
          onTap: (index) => _onItemTapped(context, index),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: widget.currentIndex == 2 && isLoggedIn
              ? const Color(0xFF9CA3AF)
              : const Color(0xFF4F46E5),
          unselectedItemColor: const Color(0xFF9CA3AF),
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
              icon: _buildLoginLogoutIcon(isLoggedIn, isLoggingOut),
              label: isLoggingOut
                  ? 'Keluar...'
                  : (isLoggedIn ? 'Keluar' : 'Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(
    int index,
    IconData iconData,
    Color activeColor,
    Color activeBg,
  ) {
    final bool isSelected = widget.currentIndex == index;
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

  Widget _buildLoginLogoutIcon(bool isLoggedIn, bool isLoggingOut) {
    final bool isSelected = widget.currentIndex == 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected && !isLoggedIn
            ? const Color(0xFFEEF2FF)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: isLoggingOut
          ? const SizedBox(
              width: 24,
              height: 24,
              child: Padding(
                padding: EdgeInsets.all(4.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFE11D48),
                ),
              ),
            )
          : Icon(
              isLoggedIn ? LucideIcons.logOut : LucideIcons.logIn,
              size: 24,
              color: isSelected && !isLoggedIn
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF9CA3AF),
            ),
    );
  }
}
