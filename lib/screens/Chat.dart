import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isLocked = false;
  String _channelName = '';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    pusher.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    final now = DateTime.now();
    final timeString =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    setState(() {
      _messages = [
        {
          'role': 'ai',
          'text': 'Halo! Saya **SafeTalk AI**. Ada yang bisa saya bantu?',
          'time': timeString,
        },
      ];
    });

    await _fetchHistory();
    await _setupPusher(); // Setup Laravel Reverb
  }

  Future<void> _setupPusher() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('safetalk_token');
    final sessionId = prefs.getString('safetalk_session');

    // Subscribe ke Public Channel sesuai dengan Token/Session
    _channelName = 'chat.${token ?? sessionId ?? 'public'}';

    try {
      await pusher.init(
        apiKey: "tsj9nxzzm2a7k0buvvbm",
        cluster: "mt1",
        proxy: 'ws://backend.safetalkai.my.id:8080',
        useTLS: false,

        onEvent: _onPusherEvent,
      );
      await pusher.subscribe(channelName: _channelName);
      await pusher.connect();
      debugPrint("✅ MANTAP! Berhasil connect ke Laravel Reverb!");
    } catch (e) {
      debugPrint("⚠️ Reverb Connection Error: $e");
    }
  }

  void _onPusherEvent(PusherEvent event) {
    if (event.eventName.contains("message.new")) {
      final data = jsonDecode(event.data);

      if (data['role'] != 'warga') {
        if (mounted) {
          setState(() {
            _messages.add({
              'role': data['role'],
              'text': data['text'],
              'time': data['time'],
              'instruction': data['instruction'],
            });

            if (data['is_locked'] != null) {
              _isLocked = (data['is_locked'] == 1 || data['is_locked'] == true);
            }
          });
          _scrollToBottom();
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('safetalk_token');
    final sessionId = prefs.getString('safetalk_session');

    Map<String, String> headers = {'Accept': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else if (sessionId != null) {
      headers['X-Session-ID'] = sessionId;
    } else {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://backend.safetalkai.my.id/api/chat/history'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _isLocked = (data['is_locked'] == 1 || data['is_locked'] == true);
            if (data['data'] != null && (data['data'] as List).isNotEmpty) {
              final now = DateTime.now();
              final timeString =
                  "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

              _messages = [
                {
                  'role': 'ai',
                  'text':
                      'Halo! Saya **SafeTalk AI**. Ada yang bisa saya bantu?',
                  'time': timeString,
                },
                ...List<Map<String, dynamic>>.from(data['data']),
              ];
            }
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint("Fetch history error: $e");
    }
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final now = DateTime.now();
    final timeString =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    setState(() {
      _messages.add({'role': 'user', 'text': text, 'time': timeString});
      _messageController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('safetalk_token');
    final sessionId = prefs.getString('safetalk_session');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else if (sessionId != null) {
      headers['X-Session-ID'] = sessionId;
    }

    try {
      final response = await http.post(
        Uri.parse('https://backend.safetalkai.my.id/api/chat/send'),
        headers: headers,
        body: jsonEncode({'message': text}),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (result['session_id'] != null && token == null) {
          await prefs.setString('safetalk_session', result['session_id']);
        }
        setState(() => _isLocked = result['is_locked'] ?? false);
        await _fetchHistory();
      }
    } catch (e) {
      debugPrint("Send error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Widget _buildFormattedText(String text, bool isFromAdmin, bool isFromAI) {
    if (text.isEmpty) return const SizedBox();

    Color defaultColor = isFromAdmin
        ? const Color(0xFF881337)
        : isFromAI
        ? const Color(0xFF334155)
        : Colors.white;

    List<TextSpan> spans = [];
    RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    Iterable<RegExpMatch> matches = exp.allMatches(text);

    int lastMatchEnd = 0;
    for (var match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: defaultColor,
          fontFamily: 'Roboto',
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        leadingWidth: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.shieldCheck,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SafeTalk AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isLocked
                            ? const Color(0xFFF43F5E)
                            : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLocked ? 'TERHUBUNG DENGAN ADMIN' : 'SISTEM AKTIF',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: _isLocked
                            ? const Color(0xFFF43F5E)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingBubble();
                }

                final msg = _messages[index];
                final isFromAdmin = msg['role'] == 'admin';
                final isFromAI = msg['role'] == 'ai';
                final isAlignedRight = msg['role'] == 'user';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isAlignedRight
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isAlignedRight) _buildAvatar(isFromAdmin, isFromAI),
                      if (!isAlignedRight) const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isAlignedRight
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isFromAdmin
                                    ? const Color(0xFFFFF1F2)
                                    : isFromAI
                                    ? Colors.white
                                    : const Color(0xFF4F46E5),
                                border: Border.all(
                                  color: isFromAdmin
                                      ? const Color(0xFFFECDD3)
                                      : isFromAI
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFF4F46E5),
                                ),
                                borderRadius: BorderRadius.circular(16)
                                    .copyWith(
                                      topLeft: !isAlignedRight
                                          ? const Radius.circular(0)
                                          : const Radius.circular(16),
                                      topRight: isAlignedRight
                                          ? const Radius.circular(0)
                                          : const Radius.circular(16),
                                    ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x05000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isFromAdmin)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.only(bottom: 4),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Color(0xFFFECDD3),
                                          ),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.shieldAlert,
                                            size: 12,
                                            color: Color(0xFFBE123C),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'PESAN ADMIN',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFBE123C),
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  _buildFormattedText(
                                    msg['text'] ?? '',
                                    isFromAdmin,
                                    isFromAI,
                                  ),

                                  if (isFromAI &&
                                      msg['instruction'] != null &&
                                      msg['instruction'].toString().isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED),
                                        border: const Border(
                                          left: BorderSide(
                                            color: Color(0xFFF97316),
                                            width: 4,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            LucideIcons.alertCircle,
                                            size: 16,
                                            color: Color(0xFFEA580C),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              msg['instruction'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF9A3412),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['time'] ?? '',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAlignedRight) const SizedBox(width: 12),
                      if (isAlignedRight) _buildAvatar(false, false),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (_isLocked)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        border: Border.all(color: const Color(0xFFFFE4E6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ADMIN SEDANG MEMANTAU PERCAKAPAN INI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: 4,
                          minLines: 1,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: _isLocked
                                ? 'Ketik pesan untuk Admin...'
                                : 'Ceritakan situasi Anda...',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _handleSend,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isAdmin, bool isAI) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isAdmin
            ? const Color(0xFFE11D48)
            : isAI
            ? const Color(0xFF4F46E5)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: !isAdmin && !isAI
            ? Border.all(color: const Color(0xFFE2E8F0))
            : null,
      ),
      child: Center(
        child: isAdmin
            ? const Icon(LucideIcons.shieldAlert, size: 16, color: Colors.white)
            : isAI
            ? const Text(
                'AI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              )
            : const Icon(LucideIcons.user, size: 16, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(_isLocked, !_isLocked),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(
                16,
              ).copyWith(topLeft: const Radius.circular(0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF94A3B8),
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
