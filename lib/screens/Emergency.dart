import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  final List<Map<String, String>> emergencyContacts = const [
    {
      "name": "DP3A Kabupaten Indramayu",
      "subtitle": "Dinas Pemberdayaan Perempuan dan Perlindungan Anak",
      "hours": "Senin - Jumat: 08:00 - 16:00",
      "number": "(0234) 272727",
      "phoneUrl": "0234272727",
    },
    {
      "name": "Komnas Perempuan",
      "subtitle": "Komisi Nasional Anti Kekerasan terhadap Perempuan",
      "hours": "24/7",
      "number": "021-3903963",
      "phoneUrl": "0213903963",
    },
    {
      "name": "Layanan Psikologis (SEJIWA)",
      "subtitle": "Layanan Psikologi untuk Sehat Jiwa",
      "hours": "24/7",
      "number": "119",
      "phoneUrl": "119",
    },
    {
      "name": "Polisi (Darurat)",
      "subtitle": "Bantuan Kepolisian Segera",
      "hours": "24/7",
      "number": "110",
      "phoneUrl": "110",
    },
  ];

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Tidak dapat memanggil $phoneNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // gray-100
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            // Header Merah Melengkung
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 48,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626), // red-600
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.shieldAlert,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Bantuan Darurat',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 60),
                    child: Text(
                      'Hubungan langsung dengan layanan dukungan keamanan.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFEE2E2),
                      ), // red-100
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alert Box Oranye
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      border: const Border(
                        left: BorderSide(color: Color(0xFFFB923C), width: 6),
                      ), // orange-400
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          color: Color(0xFFF97316),
                          size: 24,
                        ), // orange-500
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jika Anda dalam bahaya langsung',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF7C2D12),
                                ), // orange-900
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Segera hubungi 110 (Polisi) atau segera lari ke tempat aman terdekat.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9A3412).withOpacity(0.9),
                                ), // orange-800
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Kontak Layanan Dukungan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ), // gray-800
                  ),
                  const SizedBox(height: 16),

                  // List Kontak Darurat
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: emergencyContacts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final contact = emergencyContacts[index];
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact["name"]!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              contact["subtitle"]!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ), // gray-500
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16),
                              ), // gray-50
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.clock,
                                    size: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    contact["hours"]!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () =>
                                  _makePhoneCall(contact["phoneUrl"]!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF3B82F6,
                                ), // blue-500
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                                shadowColor: const Color(
                                  0xFFBFDBFE,
                                ), // blue-200
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.phone,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    contact["number"]!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Tekan tombol biru untuk melakukan panggilan langsung.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ), // gray-400
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
