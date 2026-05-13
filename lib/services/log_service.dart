import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ==========================================
// IMPORT AGEN GPS DAN PENERJEMAH LOKASI
// ==========================================
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LogService {
  static final _supabase = Supabase.instance.client;

  // ==========================================
  // FUNGSI RAHASIA UNTUK MELACAK LOKASI
  // ==========================================
  static Future<String> _dapatkanLokasi() async {
    // Kalau diakses dari web, kita abaikan saja GPS-nya biar ga ribet minta izin browser
    if (kIsWeb) return "Akses Web (Lokasi Tidak Dilacak)";

    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. Cek apakah GPS HP nyala?
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return "GPS Nonaktif";

      // 2. Cek apakah aplikasi dikasih izin akses lokasi?
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return "Izin GPS Ditolak";
      }
      if (permission == LocationPermission.deniedForever) {
        return "Izin GPS Diblokir Permanen";
      }

      // 3. Ambil titik kordinat (Dibatasi 5 detik biar HP ga nge-hang kalau sinyal jelek)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      // 4. Terjemahkan kordinat (Misal: 0.502, 117.153) jadi nama daerah
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Akan menghasilkan teks seperti: "Samarinda, Kalimantan Timur" atau nama kecamatan
        return "${place.subLocality ?? place.locality}, ${place.administrativeArea}";
      }
      
      // Kalau gagal menerjemahkan, kembalikan angkanya saja
      return "${position.latitude}, ${position.longitude}";

    } catch (e) {
      debugPrint("Gagal melacak lokasi: $e");
      return "Lokasi Tidak Terdeteksi";
    }
  }

  static Future<void> catatAktivitas({
    required String modul,
    required String aksi,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String userId = _supabase.auth.currentUser?.id ?? '';
      final String namaUser = prefs.getString('user_name') ?? 'Pengurus'; 
      final String divisiUser = prefs.getString('user_role') ?? 'Admin'; 

      String namaPerangkat = "Perangkat Tidak Diketahui";
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
        namaPerangkat = "Web Browser (${webInfo.browserName.name.toUpperCase()})";
      } else {
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          namaPerangkat = "${androidInfo.brand} ${androidInfo.model}".toUpperCase();
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          namaPerangkat = iosInfo.name; 
        } else if (Platform.isWindows) {
          namaPerangkat = "Aplikasi Windows Desktop";
        }
      }

      // ==========================================
      // PANGGIL AGEN PELACAK SEBELUM KIRIM DATA
      // ==========================================
      String lokasiUser = await _dapatkanLokasi();

      await _supabase.from('log_aktivitas').insert({
        'id_user': userId.isNotEmpty ? userId : null,
        'nama_user': namaUser,
        'divisi_user': divisiUser,
        'modul': modul,
        'aksi': aksi,
        'nama_perangkat': namaPerangkat, 
        'lokasi': lokasiUser, // <--- MASUKKAN KE LACI BARU DI SUPABASE
      });

      debugPrint("✅ Log dicatat dari perangkat: $namaPerangkat di $lokasiUser");

    } catch (e) {
      debugPrint("❌ Gagal mencatat log: $e");
    }
  }
}