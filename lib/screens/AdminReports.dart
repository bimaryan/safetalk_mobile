import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import 'AdminCaseDetail.dart';

class AdminReports extends StatefulWidget {
  const AdminReports({super.key});

  @override
  State<AdminReports> createState() => _AdminReportsState();
}

class _AdminReportsState extends State<AdminReports> {
  List<dynamic> reports = [];
  bool isLoading = true;
  bool isExporting = false; // State untuk loading export
  String searchQuery = "";
  int currentPage = 1;
  int lastPage = 1;
  int totalData = 0;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports({int page = 1}) async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('safetalk_token');

      final response = await http.get(
        Uri.parse(
          'https://backend.safetalkai.my.id/api/admin/reports?page=$page&search=$searchQuery',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          reports = result['data']['data'];
          currentPage = result['data']['current_page'];
          lastPage = result['data']['last_page'];
          totalData = result['data']['total'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Reports Error: $e");
      setState(() => isLoading = false);
    }
  }

  // --- FUNGSI EXPORT EXCEL ---
  Future<void> handleExportExcel() async {
    setState(() => isExporting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('safetalk_token');

      // 1. Lakukan request ke API untuk mengambil file (blob/bytes)
      final response = await http.get(
        Uri.parse(
          'https://backend.safetalkai.my.id/api/admin/reports/export?search=$searchQuery',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // 2. Tentukan lokasi folder penyimpanan
        Directory? directory;
        if (Platform.isAndroid) {
          // Paksa simpan di folder Download bawaan Android
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory =
                await getExternalStorageDirectory(); // Fallback jika gagal
          }
        } else {
          // Untuk iOS
          directory = await getApplicationDocumentsDirectory();
        }

        // 3. Buat nama file dan tulis datanya
        final String dateStr = DateTime.now().toIso8601String().split('T')[0];
        final String fileName = 'Laporan-SafeTalk-$dateStr.xlsx';
        final File file = File('${directory!.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Berhasil! File Excel disimpan di: ${file.path}"),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception("Gagal mengunduh file dari server.");
      }
    } catch (e) {
      debugPrint("Export Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengunduh file: $e"),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  Color _getBadgeColor(String category) {
    if (category == "NON_KDRT" || category == "SAPAAN") return Colors.green;
    if (["K1", "K3", "K5"].contains(category)) return Colors.red;
    if (["K2", "K4"].contains(category)) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Data Laporan Masuk",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(
            "Total $totalData laporan ditemukan.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),

          // --- TOMBOL EXPORT & SEARCH BAR ---
          TextField(
            controller: _searchController,
            onSubmitted: (value) {
              setState(() => searchQuery = value);
              fetchReports(page: 1);
            },
            decoration: InputDecoration(
              hintText: "Cari ID / Nama...",
              prefixIcon: const Icon(LucideIcons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12), // Jarak antara search dan tombol
          ElevatedButton.icon(
            onPressed: isExporting ? null : handleExportExcel,
            icon: isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    LucideIcons.download,
                    size: 16,
                    color: Colors.white,
                  ),
            label: Text(
              isExporting ? "Proses..." : "Export Excel",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 16),

          // ListView Data
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final category = report['latest_category'] ?? 'Umum';
                      final badgeColor = _getBadgeColor(category);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            report['user'] != null
                                ? report['user']['nama_lengkap']
                                : "Anonymous",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "ID: #${report['case_id'] ?? report['id']}",
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              LucideIcons.eye,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminCaseDetail(
                                    id: report['id'].toString(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Pagination
          if (!isLoading && reports.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hal $currentPage dari $lastPage",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.chevronLeft),
                      onPressed: currentPage > 1
                          ? () => fetchReports(page: currentPage - 1)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.chevronRight),
                      onPressed: currentPage < lastPage
                          ? () => fetchReports(page: currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
