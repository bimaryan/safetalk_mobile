import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminCaseDetail extends StatefulWidget {
  final String id;
  const AdminCaseDetail({super.key, required this.id});

  @override
  State<AdminCaseDetail> createState() => _AdminCaseDetailState();
}

class _AdminCaseDetailState extends State<AdminCaseDetail> {
  bool isLoading = true;
  Map<String, dynamic>? triggerReport;
  List<dynamic> thread = [];
  bool isLocked = false;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('safetalk_token');

      final response = await http.get(
        Uri.parse('https://backend.safetalkai.my.id/api/admin/reports/${widget.id}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          triggerReport = result['data']['room'];
          thread = result['data']['thread'];
          isLocked = result['data']['is_locked'];
          isLoading = false;
        });
        
        // Auto scroll ke bawah
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (e) {
      debugPrint("Detail Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> sendAdminReply() async {
    if (_msgController.text.trim().isEmpty) return;

    final message = _msgController.text;
    _msgController.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('safetalk_token');

      await http.post(
        Uri.parse('https://backend.safetalkai.my.id/api/admin/reports/${widget.id}/reply'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          'reply_to_id': null,
        }),
      );
      fetchDetail();
    } catch (e) {
      debugPrint("Reply Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Ruang Intervensi", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Info Card Top
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(LucideIcons.user, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(triggerReport?['user'] != null ? triggerReport!['user']['nama_lengkap'] : "Anonymous", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Kasus: ${triggerReport?['latest_category'] ?? 'Umum'}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Chat Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: thread.length,
              itemBuilder: (context, index) {
                final chat = thread[index];
                bool isAdmin = chat['role'] == 'admin';
                bool isUser = chat['role'] == 'user';
                
                return Align(
                  alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAdmin ? Colors.red.shade50 : (isUser ? Colors.white : Colors.indigo.shade50),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isAdmin ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: isAdmin ? const Radius.circular(16) : const Radius.circular(0),
                      ),
                      border: Border.all(color: isAdmin ? Colors.red.shade200 : Colors.grey.shade200)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isAdmin) const Text("PESAN ADMIN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                        Text(chat['text'], style: TextStyle(color: isAdmin ? Colors.red.shade900 : Colors.black87)),
                        const SizedBox(height: 4),
                        Text(chat['time'] ?? '', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: "Kirim intervensi admin...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                    onPressed: sendAdminReply,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}