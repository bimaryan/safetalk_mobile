import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool isLoading = true;
  Map<String, dynamic> stats = {};
  List<dynamic> recentReports = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardStats();
  }

  Future<void> fetchDashboardStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('safetalk_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse('https://backend.safetalkai.my.id/api/admin/dashboard'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          stats = result['data'];
          recentReports = result['data']['recent_reports'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      setState(() => isLoading = false);
    }
  }

  int getCount(String key) {
    if (stats['category_distribution'] == null) return 0;
    return int.tryParse(stats['category_distribution'][key]?.toString() ?? '0') ?? 0;
  }

  double calculatePercentage(int value, int total) {
    if (total == 0) return 0.0;
    return (value / total);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    int totalKasus = int.tryParse(stats['total_chats']?.toString() ?? '0') ?? 0;
    int risikoTinggi = getCount('K4') + getCount('K5');
    int risikoSedang = getCount('K2') + getCount('K3');
    int risikoRendah = getCount('K1');
    int nonKdrt = getCount('NON_KDRT');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3 Stats Card (Scrollable Horizontal for mobile)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard(totalKasus.toString(), "Total Interaksi Chat", LucideIcons.messageSquare, Colors.indigo),
                const SizedBox(width: 16),
                _buildStatCard(risikoTinggi.toString(), "Indikasi Risiko Tinggi", LucideIcons.alertTriangle, Colors.red),
                const SizedBox(width: 16),
                _buildStatCard((stats['total_users'] ?? 0).toString(), "Warga Terdaftar", LucideIcons.users, Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Chart Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Icon(LucideIcons.barChart2, color: Colors.blue.shade600, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text("Distribusi Tingkat Risiko", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                if (totalKasus > 0)
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          if (risikoTinggi > 0) PieChartSectionData(color: Colors.red, value: risikoTinggi.toDouble(), title: '${((risikoTinggi/totalKasus)*100).toStringAsFixed(1)}%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (risikoSedang > 0) PieChartSectionData(color: Colors.orange, value: risikoSedang.toDouble(), title: '${((risikoSedang/totalKasus)*100).toStringAsFixed(1)}%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (risikoRendah > 0) PieChartSectionData(color: Colors.blue, value: risikoRendah.toDouble(), title: '${((risikoRendah/totalKasus)*100).toStringAsFixed(1)}%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (nonKdrt > 0) PieChartSectionData(color: Colors.green, value: nonKdrt.toDouble(), title: '${((nonKdrt/totalKasus)*100).toStringAsFixed(1)}%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                if (totalKasus > 0) const SizedBox(height: 24),
                _buildProgressBar("Risiko Tinggi / Darurat (K4, K5)", risikoTinggi, totalKasus, Colors.red),
                const SizedBox(height: 16),
                _buildProgressBar("Risiko Sedang (K2, K3)", risikoSedang, totalKasus, Colors.orange),
                const SizedBox(height: 16),
                _buildProgressBar("Risiko Rendah (K1)", risikoRendah, totalKasus, Colors.blue),
                const SizedBox(height: 16),
                _buildProgressBar("Konsultasi Umum (NON_KDRT)", nonKdrt, totalKasus, Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent List
          Row(
            children: [
              Icon(LucideIcons.clock, size: 20, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              const Text("Riwayat Interaksi AI Terbaru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...recentReports.map((report) => _buildRecentReportItem(report)).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title, IconData icon, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: Icon(icon, size: 100, color: color.withOpacity(0.05))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    double percent = calculatePercentage(value, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            Text("${(percent * 100).toStringAsFixed(1)}%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text("$value Interaksi", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
      ],
    );
  }

  Widget _buildRecentReportItem(dynamic report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                    child: Text("ID-${report['id']}", style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: report['user_id'] != null ? Colors.blue.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Text(report['user_id'] != null ? "Terdaftar" : "Anonim", 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: report['user_id'] != null ? Colors.blue : Colors.grey)),
                  )
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text("Kategori: ${report['category']}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(report['user'] != null ? report['user']['nama_lengkap'] : "Anonymous User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('"${report['message']}"', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}