import 'package:flutter/material.dart';
import '../core/colors.dart';

class RevenueCard extends StatelessWidget {
  const RevenueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("DAILY REVENUE",
                style: TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 12),
            const Text("Rp 12.482.900",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.trending_up, color: AppColors.success),
                SizedBox(width: 6),
                Text("+14%",
                    style: TextStyle(color: AppColors.success))
              ],
            )
          ],
        ),
      ),
    );
  }
}