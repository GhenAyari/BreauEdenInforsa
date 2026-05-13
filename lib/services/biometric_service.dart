import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart'; // Tambahan buat ngilangin garis biru debugPrint

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // 1. Cek apakah HP punya sensor sidik jari/Face ID
  static Future<bool> hasBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint("Error cek biometrik: $e");
      return false;
    }
  }

  // 2. Munculin Popup Sidik Jari
  static Future<bool> authenticate() async {
    final isAvailable = await hasBiometrics();
    if (!isAvailable) return false;

    try {
      // =======================================================
      // JURUS ANTI REWEL: Cukup panggil alasan utamanya saja!
      // =======================================================
      return await _auth.authenticate(
        localizedReason: 'Tempelkan sidik jari Anda untuk masuk ke Aplikasi Bureau',
      );
    } on PlatformException catch (e) {
      debugPrint("Error autentikasi: $e");
      return false;
    }
  }
}