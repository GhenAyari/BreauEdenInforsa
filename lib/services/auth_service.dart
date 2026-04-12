import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<bool> login(String email, String password) async {
    try {
      // Meminta Supabase untuk mencocokkan email dan password
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Jika berhasil dan mendapat sesi (session), kembalikan true
      if (res.session != null) {
        return true;
      }
      return false;
    } catch (e) {
      // Jika email/password salah, Supabase otomatis melempar error ke sini
      print("Login Gagal: $e");
      return false;
    }
  }

  // Bonus Fungsi: Untuk Logout (jika nanti kamu butuhkan)
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}