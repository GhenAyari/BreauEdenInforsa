import 'package:flutter/material.dart';
import '../core/colors.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'stock_screen.dart';
import 'report_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final pages = const [
    DashboardScreen(),
    PosScreen(),
    StockScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        height: 75,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: "Home"),
          NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: "POS"),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: "Stock"),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: "Reports"),
        ],
      ),
    );
  }
}