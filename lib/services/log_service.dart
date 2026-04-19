import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogService {
  static final _supabase = Supabase.instance.client;

  static Future<void> catatAktivitas({
    required String modul,
    required String aksi,
  }) async {
    try {
      // 1. Ambil Identitas User yang lagi Login
      final prefs = await SharedPreferences.getInstance();
      final String userId = _supabase.auth.currentUser?.id ?? '';
      // Pastikan key ini sama dengan yang kamu pakai pas login ya
      final String namaUser = prefs.getString('user_name') ?? 'Pengurus'; 
      final String divisiUser = prefs.getString('user_role') ?? 'Admin'; 

      // 2. Operasi Intelijen: Lacak Merek HP / Perangkat
      String namaPerangkat = "Perangkat Tidak Diketahui";
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
        namaPerangkat = "Web Browser (${webInfo.browserName.name.toUpperCase()})";
      } else {
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          // Hasilnya misal: "Infinix X6833B" atau "samsung SM-A528B"
          namaPerangkat = "${androidInfo.brand} ${androidInfo.model}".toUpperCase();
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          namaPerangkat = iosInfo.name; // Hasilnya misal: "iPhone 13"
        } else if (Platform.isWindows) {
          namaPerangkat = "Aplikasi Windows Desktop";
        }
      }

      // 3. Kirim Data Lengkap ke Supabase
      await _supabase.from('log_aktivitas').insert({
        'id_user': userId.isNotEmpty ? userId : null,
        'nama_user': namaUser,
        'divisi_user': divisiUser,
        'modul': modul,
        'aksi': aksi,
        'nama_perangkat': namaPerangkat, 
      });

      debugPrint("✅ Log berhasil dicatat dari perangkat: $namaPerangkat");

    } catch (e) {
      debugPrint("❌ Gagal mencatat log: $e");
    }
  }
}