import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/colors.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'stock_screen.dart';
import 'rental_screen.dart';
import 'preorder_screen.dart';
import 'account_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String _userRole = "";
  bool _isLoading = true;

  List<Widget> _pages = [];
  List<NavigationDestination> _destinations = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString("user_role") ?? "Admin";
      _buildNavigation();
      _isLoading = false;
    });
  }

  void _buildNavigation() {
    // Semua Role pasti punya halaman Home
    _pages = [const DashboardScreen()];
    _destinations = [const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: "Home")];

    if (_userRole == 'Admin') {
     _pages.addAll([const PosScreen(), const StockScreen(), const AccountScreen()]);
      _destinations.addAll([
        const NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: "POS"),
        const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: "Stock"),
        const NavigationDestination(icon: Icon(Icons.manage_accounts_outlined), selectedIcon: Icon(Icons.manage_accounts), label: "Akun"), // Nanti diganti jadi CRUD User
      ]);
    } 
    else if (_userRole == 'POS_Barang') {
      _pages.addAll([const PosScreen(), const StockScreen()]);
      _destinations.addAll([
        const NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: "POS"),
        const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: "Stock"),
      ]);
    } 
    else if (_userRole == 'Penyewaan') {
      _pages.addAll([const RentalScreen(), const StockScreen()]);
      _destinations.addAll([
        const NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag), label: "Sewa"),
        const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: "Stock"),
      ]);
    }
    else if (_userRole == 'PreOrder') {
      _pages.add(const PreOrderScreen());
      _destinations.add(const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: "PO"));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // FITUR BARU: Deteksi mode tema saat ini (Light / Dark)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        height: 75,
        // PERBAIKAN: Jika Dark Mode -> pakai warna tema gelap, jika Light Mode -> Putih
        backgroundColor: isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _destinations,
      ),
    );
  }
}