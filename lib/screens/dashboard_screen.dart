import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../widgets/revenue_card.dart';
import '../widgets/action_card.dart';
import 'rental_screen.dart'; // Sudah benar import-nya
import 'preorder_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("BUREAU",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 20),

            /// Revenue Card
            const RevenueCard(),

            const SizedBox(height: 20),

            /// Quick Actions
           /// Quick Actions
            /// Quick Actions
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                
                // KOTAK PENYEWAAN YANG SUDAH PINTAR SEKARANG
                ActionCard(
                  title: "Penyewaan", 
                  icon: Icons.shopping_bag,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RentalScreen()),
                    );
                  },
                ),
                
      
                ActionCard(
                  title: "Pre-Order", 
                  icon: Icons.receipt_long,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PreOrderScreen()),
                    );
                  },
                ),
                
              ],
            ),
          ],
        ),
      ),
    );
  }
}