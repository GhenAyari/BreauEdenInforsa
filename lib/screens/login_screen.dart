import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/colors.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool success = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (_rememberMe) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool("isLoggedIn", true);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email atau Password salah"),
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
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    /// Logo / Title
                    const Text(
                      "BUREAU",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text("Sistem Informasi Penjualan dan Stok Barang"),

                    const SizedBox(height: 30),

                    /// Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email atau ID Karyawan",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Email wajib diisi" : null,
                    ),

                    const SizedBox(height: 18),

                    /// Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: "Kata Sandi",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() => _obscure = !_obscure);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) =>
                          value!.length < 6 ? "Minimal 6 karakter" : null,
                    ),

                    const SizedBox(height: 14),

                    /// Remember Me
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (val) {
                            setState(() => _rememberMe = val!);
                          },
                        ),
                        const Text("Ingat saya di perangkat ini")
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Masuk",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {},
                      child: const Text("Lupa Kata Sandi?"),
                    ),
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