import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import screen yang akan dipanggil
import '../screens/AdminDashboard.dart';
import '../screens/AdminReports.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final Color primaryBlue = const Color(0xFF4F46E5); // Indigo 600
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate800 = const Color(0xFF1E293B);
  final Color slate300 = const Color(0xFFCBD5E1);

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  final List<Widget> _pages = [
    const AdminDashboard(),
    const AdminReports(),
  ];

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar dari Panel Admin?"),
        content: const Text("Sesi Anda akan diakhiri secara aman."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('safetalk_token');

      if (token != null) {
        try {
          await http.post(
            Uri.parse('https://backend.safetalkai.my.id/api/auth/logout'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (e) {
          debugPrint("Logout API error: $e");
        }
      }

      await prefs.clear();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF475569)), // slate-600
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ADMIN PANEL",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Row(
              children: [
                const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  formattedDate.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell),
                onPressed: () {},
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: slate900,
        child: Column(
          children: [
            // Header Logo
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: slate800)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SafeTalk AI",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        "ADMIN PANEL",
                        style: TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ],
                  )
                ],
              ),
            ),
            // Menu Navigasi
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMenuItem(LucideIcons.layoutDashboard, "Dashboard", 0),
                  const SizedBox(height: 8),
                  _buildMenuItem(LucideIcons.fileText, "Data Laporan", 1),
                ],
              ),
            ),
            // Footer (Profile & Logout)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: slate800)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: slate800.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.user, color: primaryBlue, size: 16),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ROLE", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                            Text("Administrator", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(LucideIcons.logOut, size: 16, color: Colors.white),
                    label: const Text("Keluar Panel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      side: BorderSide(color: slate800),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 48),
                    ).copyWith(
                      overlayColor: MaterialStateProperty.all(Colors.red.shade600),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    bool isActive = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context); // Tutup drawer
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : slate300),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : slate300,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}