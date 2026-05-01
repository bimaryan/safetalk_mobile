import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PanduanScreen extends StatelessWidget {
  const PanduanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: const Text(
          'Panduan Penggunaan',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, color: Color(0xFF2563EB), size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'SafeTalk AI adalah ruang aman Anda. Berikut cara menggunakan aplikasi ini dengan efektif.',
                      style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildGuideItem(
              LucideIcons.messageSquare,
              '1. Ceritakan Secara Rinci',
              'Gunakan fitur chat untuk menceritakan kronologi kejadian. Semakin detail, semakin baik AI kami dapat mengklasifikasikan tingkat risiko Anda.',
            ),
            _buildGuideItem(
              LucideIcons.shieldCheck,
              '2. Privasi Terjamin',
              'Jika Anda menggunakan Mode Anonim, tidak ada data pribadi yang dilacak. Anda aman untuk berbicara.',
            ),
            _buildGuideItem(
              LucideIcons.phoneCall,
              '3. Gunakan Tombol Darurat',
              'Jika Anda merasa nyawa Anda terancam, segera tinggalkan chat dan gunakan menu Darurat untuk memanggil Polisi atau DP3A.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
