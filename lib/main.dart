import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() {
  runApp(const InForsaApp());
}

class InForsaApp extends StatefulWidget {
  const InForsaApp({super.key});

  @override
  State<InForsaApp> createState() => _InForsaAppState();
}

class _InForsaAppState extends State<InForsaApp> {
  Widget _startScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool("isLoggedIn") ?? false;

    if (loggedIn) {
      setState(() {
        _startScreen = const MainNavigation();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: _startScreen,
    );
  }
}