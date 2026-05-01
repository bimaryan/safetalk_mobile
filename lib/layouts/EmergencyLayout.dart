import 'package:flutter/material.dart';

// Import komponen dan screen yang dibutuhin
import '../components/BottomNav.dart';
import '../screens/Emergency.dart'; // Pastikan path ini sesuai sama letak file Emergency lu

class EmergencyLayout extends StatelessWidget {
  const EmergencyLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // Body-nya langsung manggil isi halaman Emergency
      body: EmergencyScreen(),

      // BottomNav-nya kita panggil, dan set index ke 1 (karena Darurat itu tab ke-2)
      bottomNavigationBar: CustomBottomNav(currentIndex: 1),
    );
  }
}
