import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load file .env terlebih dahulu
  await dotenv.load(fileName: ".env");

  // 2. Ambil URL dan Key dari .env untuk inisialisasi Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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