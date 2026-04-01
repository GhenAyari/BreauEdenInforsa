import 'dart:async';

class AuthService {
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    // Simulasi login (nanti bisa ganti API)
    if (email == "admin@bureau.com" && password == "123456") {
      return true;
    } else {
      return false;
    }
  }
}