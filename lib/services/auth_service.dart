import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final _supabase = Supabase.instance.client;


  Future<String?> login(String email, String password) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session != null && res.user != null) {
        // Ambil data divisi dari tabel 'pengurus'
        final userData = await _supabase
            .from('pengurus')
            .select('divisi_akses, nama_lengkap')
            .eq('id', res.user!.id)
            .maybeSingle();

        SharedPreferences prefs = await SharedPreferences.getInstance();
        
        if (userData != null) {
          // Simpan Nama dan Divisi ke memori lokal
          await prefs.setString("user_role", userData['divisi_akses']);
          await prefs.setString("user_name", userData['nama_lengkap']);
          return userData['divisi_akses'];
        } else {
          // Fallback jika data di tabel pengurus belum ada
          await prefs.setString("user_role", "Admin");
          await prefs.setString("user_name", "Admin Utama");
          return "Admin";
        }
      }
      return null;
    } catch (e) {
      print("Login Gagal: $e");
      return null;
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    await _supabase.auth.signOut();
  }
}