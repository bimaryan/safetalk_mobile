import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _agreeTerms = false;
  String _errorMsg = "";

  final Color primaryBlue = const Color(0xFF3B82F6);
  final Color slate800 = const Color(0xFF1E293B);
  final Color slate700 = const Color(0xFF334155);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate50 = const Color(0xFFF8FAFC);
  final Color slate100 = const Color(0xFFF1F5F9);

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMsg = "Konfirmasi password tidak cocok!");
      return;
    }
    if (!_agreeTerms) {
      setState(() => _errorMsg = "Anda harus menyetujui Syarat & Ketentuan.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = "";
    });

    try {
      final response = await http.post(
        Uri.parse('https://backend.safetalkai.my.id/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nama_lengkap': _namaController.text,
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (result['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('safetalk_token', result['token']);
          await prefs.setBool('isAuthenticated', true);
          await prefs.setString(
            'userRole',
            'warga',
          ); // Default role saat register biasanya warga
          await prefs.remove('safetalk_session');

          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/auth_gate');
        }
      } else {
        setState(() {
          if (result['errors'] != null) {
            final errors = result['errors'] as Map<String, dynamic>;
            _errorMsg = errors[errors.keys.first][0];
          } else {
            _errorMsg = result['message'] ?? "Gagal melakukan registrasi.";
          }
        });
      }
    } catch (e) {
      setState(
        () => _errorMsg = "Gagal terhubung ke server. Pastikan backend aktif.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool? showPassState,
    VoidCallback? onTogglePass,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: slate700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: isPassword ? !(showPassState ?? false) : false,
            style: TextStyle(color: slate700, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: slate400,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icon, color: slate400, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        showPassState! ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: slate400,
                        size: 20,
                      ),
                      onPressed: onTogglePass,
                    )
                  : null,
              filled: true,
              fillColor: slate50,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: slate100, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: slate100, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: primaryBlue.withOpacity(0.5),
                  width: 4,
                ),
              ),
            ),
            validator: (val) => val!.isEmpty ? 'Tidak boleh kosong' : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: slate800),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Daftar Akun',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: slate800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lengkapi data di bawah untuk memulai sesi Anda.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: slate500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMsg.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12),
                          left: Radius.circular(4),
                        ),
                        border: const Border(
                          left: BorderSide(color: Colors.red, width: 4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.alertCircle,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMsg,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildInput(
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama lengkap',
                    icon: LucideIcons.user,
                    controller: _namaController,
                  ),
                  _buildInput(
                    label: 'Username',
                    hint: 'Masukkan username',
                    icon: LucideIcons.user,
                    controller: _usernameController,
                  ),
                  _buildInput(
                    label: 'Email',
                    hint: 'nama@email.com',
                    icon: LucideIcons.mail,
                    controller: _emailController,
                  ),
                  _buildInput(
                    label: 'Password',
                    hint: 'Buat password baru (Min. 6 Karakter)',
                    icon: LucideIcons.lock,
                    controller: _passwordController,
                    isPassword: true,
                    showPassState: _showPassword,
                    onTogglePass: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  _buildInput(
                    label: 'Konfirmasi Password',
                    hint: 'Ulangi password',
                    icon: LucideIcons.lock,
                    controller: _confirmPasswordController,
                    isPassword: true,
                    showPassState: _showConfirmPassword,
                    onTogglePass: () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword,
                    ),
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreeTerms,
                          onChanged: (val) =>
                              setState(() => _agreeTerms = val ?? false),
                          activeColor: primaryBlue,
                          side: BorderSide(color: slate400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: slate500,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'Saya menyetujui '),
                              TextSpan(
                                text: 'Syarat & Ketentuan',
                                style: TextStyle(color: primaryBlue),
                              ),
                              const TextSpan(text: ' serta '),
                              TextSpan(
                                text: 'Kebijakan Privasi',
                                style: TextStyle(color: primaryBlue),
                              ),
                              const TextSpan(text: ' SafeTalkAI.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      disabledBackgroundColor: slate400,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: primaryBlue.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.userPlus,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Daftar Sekarang',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: TextStyle(
                          color: slate500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Masuk di sini',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.underline,
                            decorationColor: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
