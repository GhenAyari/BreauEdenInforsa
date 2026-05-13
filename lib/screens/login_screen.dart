import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/colors.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';
// ========================================================
// IMPORT AGEN RAHASIA BIOMETRIK
// ========================================================
import '../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscure = true;
  bool _isBiometricEnabled = false; // Deteksi apakah user ngidupin fitur sidik jari

  @override
  void initState() {
    super.initState();
    _cekBiometrikOtomatis(); // Panggil pengecekan saat layar pertama kali dibuka
  }

  // ========================================================
  // FITUR BARU: CEK & PANGGIL SIDIK JARI OTOMATIS
  // ========================================================
  Future<void> _cekBiometrikOtomatis() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool useFingerprint = prefs.getBool('use_fingerprint') ?? false;

    if (useFingerprint) {
      setState(() => _isBiometricEnabled = true);
      _loginDenganSidikJari(); // Langsung tembak popup sidik jari!
    }
  }

  Future<void> _loginDenganSidikJari() async {
    bool success = await BiometricService.authenticate();
    
    if (success) {
      // Kalau sidik jari cocok, anggap aja ingat sesi & langsung masuk!
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil masuk dengan Sidik Jari!"), backgroundColor: Colors.green),
        );
      }
    } else {
      // Kalau gagal/dibatalkan, kasih tau aja (tapi biarin user ketik manual)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sidik Jari dibatalkan/gagal. Silakan masuk manual."), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? role = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (role != null) {
      if (_rememberMe) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isLoggedIn", true);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email atau Kata Sandi salah, atau akun tidak ada."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("BUREAU", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 2)),
                    const SizedBox(height: 6),
                    const Text("Sistem Informasi Himpunan", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: "Email Pengurus", prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                      validator: (value) => value!.isEmpty ? "Email wajib diisi" : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: "Kata Sandi",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (value) => value!.length < 6 ? "Minimal 6 karakter" : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Checkbox(value: _rememberMe, onChanged: (val) => setState(() => _rememberMe = val!), activeColor: AppColors.primary),
                        const Text("Ingat saya")
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Masuk", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    // ========================================================
                    // TAMPILAN TOMBOL SIDIK JARI MANUAL (MUNCUL KALAU FITUR AKTIF)
                    // ========================================================
                    if (_isBiometricEnabled) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(height: 1, width: 40, color: Colors.grey.shade300),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text("Atau masuk dengan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                          Container(height: 1, width: 40, color: Colors.grey.shade300),
                        ],
                      ),
                      const SizedBox(height: 15),
                      InkWell(
                        onTap: _loginDenganSidikJari,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.1),
                            border: Border.all(color: Colors.blue.withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.fingerprint, color: Colors.blue, size: 35),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}