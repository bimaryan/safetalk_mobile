import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _tanggalLahirController; // <-- Tambahan Controller
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // Isi form otomatis dengan data yang ada
    _namaController = TextEditingController(
      text: widget.userData['nama_lengkap'],
    );
    _usernameController = TextEditingController(
      text: widget.userData['username'],
    );
    _emailController = TextEditingController(
      text:
          (widget.userData['email'] == null ||
              widget.userData['email'] == 'Tidak tersedia')
          ? ''
          : widget.userData['email'],
    );
    // Isi tanggal lahir jika ada
    _tanggalLahirController = TextEditingController(
      text: widget.userData['tanggal_lahir'] ?? '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _tanggalLahirController.dispose(); // <-- Jangan lupa di-dispose
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNGSI MUNCULKAN KALENDER ---
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();

    // Jika sudah ada tanggal lahir sebelumnya, buka kalender di tanggal tersebut
    if (_tanggalLahirController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_tanggalLahirController.text);
      } catch (e) {
        initialDate = DateTime.now();
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900), // Batas tahun paling tua
      lastDate: DateTime.now(), // Batas tahun paling baru (hari ini)
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5), // Warna header kalender
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    // Jika user memilih tanggal, format menjadi YYYY-MM-DD untuk Laravel
    if (picked != null) {
      setState(() {
        _tanggalLahirController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('safetalk_token');

      // Masukkan tanggal_lahir ke body request
      Map<String, dynamic> body = {
        'nama_lengkap': _namaController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        'tanggal_lahir': _tanggalLahirController.text, // <-- Tambahan payload
      };

      // Hanya kirim password jika user mengetik sesuatu
      if (_passwordController.text.isNotEmpty) {
        body['password'] = _passwordController.text;
      }

      final response = await http.put(
        Uri.parse('https://backend.safetalkai.my.id/api/auth/user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Kembali & beritahu ProfileScreen untuk refresh
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memperbarui profil.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('NAMA LENGKAP'),
              _buildTextField(
                controller: _namaController,
                hint: 'Masukkan nama lengkap',
                icon: LucideIcons.user,
              ),
              const SizedBox(height: 20),

              _buildInputLabel('USERNAME'),
              _buildTextField(
                controller: _usernameController,
                hint: 'Masukkan username',
                icon: LucideIcons.atSign,
              ),
              const SizedBox(height: 20),

              _buildInputLabel('EMAIL'),
              _buildTextField(
                controller: _emailController,
                hint: 'Masukkan email',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // --- FIELD TANGGAL LAHIR ---
              _buildInputLabel('TANGGAL LAHIR'),
              TextFormField(
                controller: _tanggalLahirController,
                readOnly:
                    true, // Dibuat readOnly agar keyboard tidak muncul, hanya kalender
                onTap: () => _selectDate(context),
                validator: (value) =>
                    value!.isEmpty ? 'Tidak boleh kosong' : null,
                decoration: InputDecoration(
                  hintText: 'Pilih tanggal lahir (YYYY-MM-DD)',
                  prefixIcon: const Icon(
                    LucideIcons.calendar,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildInputLabel('PASSWORD BARU (OPSIONAL)'),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  hintText: 'Kosongkan jika tidak ingin ganti',
                  prefixIcon: const Icon(
                    LucideIcons.lock,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF334155),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty ? 'Tidak boleh kosong' : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
