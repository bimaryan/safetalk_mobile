import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomNavbar extends StatelessWidget implements PreferredSizeWidget {
  const CustomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0055A5), // Sama kayak bg-[#0055A5]
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      automaticallyImplyLeading: false, // Ilangin tombol back bawaan
      title: Row(
        children: [
          // Icon Shield
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.shield,
              color: Color(0xFF0055A5),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SafeTalkAI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'Mode Anonim',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFDBEAFE),
                ), // blue-100
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Bell Icon dengan Red Dot
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                LucideIcons.bell,
                color: Color(0xFFDBEAFE),
                size: 22,
              ),
              onPressed: () {},
              highlightColor: Colors.blue[600],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red[500],
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0055A5), width: 2),
                ),
              ),
            ),
          ],
        ),

        // User Avatar
        Container(
          margin: const EdgeInsets.only(right: 16, left: 8),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: const Center(
            child: Text(
              'UJ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
