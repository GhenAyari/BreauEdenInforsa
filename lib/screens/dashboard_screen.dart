import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/colors.dart';
import '../widgets/revenue_card.dart';
import '../widgets/action_card.dart';
import 'rental_screen.dart'; 
import 'preorder_screen.dart';
import '../services/auth_service.dart'; 
import 'login_screen.dart'; 
import 'log_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userRole = "";
  String _userName = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString("user_role") ?? "Admin";
      _userName = prefs.getString("user_name") ?? "Pengurus";
      _isLoading = false;
    });
  }


  Future<void> _handleLogout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar Akun", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Keluar")
          ),
        ],
      )
    ) ?? false;

    if (confirm) {
     
      await AuthService().logout();
      
      if (mounted) {
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, 
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
        
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("BUREAU", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Text("Halo, $_userName!", style: const TextStyle(fontSize: 16, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Lencana Divisi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
                      child: Text(_userRole, style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 4),
                    // TOMBOL LOGOUT
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      tooltip: "Keluar Akun",
                      onPressed: _handleLogout,
                    )
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),

            if (_userRole == 'Admin' || _userRole == 'POS_Barang') ...[
              const RevenueCard(),
              const SizedBox(height: 20),
            ],

            const Text("Akses Cepat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                // Kotak Penyewaan
                if (_userRole == 'Admin' || _userRole == 'Penyewaan')
                  ActionCard(
                    title: "Penyewaan", 
                    icon: Icons.shopping_bag,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RentalScreen())),
                  ),
                
                // Kotak Pre-Order
                if (_userRole == 'Admin' || _userRole == 'PreOrder')
                  ActionCard(
                    title: "Pre-Order", 
                    icon: Icons.receipt_long,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PreOrderScreen())),
                  ),
                  // Kotak Riwayat Aktivitas (Bisa dilihat semua orang, tapi RLS Supabase yang memfilter isinya)
                ActionCard(
                  title: "Riwayat", 
                  icon: Icons.history,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LogScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}