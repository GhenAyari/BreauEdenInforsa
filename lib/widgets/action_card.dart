import 'package:flutter/material.dart';
import '../core/colors.dart';

class ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap; // <--- KUNCI UTAMANYA DI SINI

  const ActionCard({
    super.key,
    required this.title,
    required this.icon,
    this.onTap, // <--- TAMBAHKAN DI SINI
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Hapus margin atau elevation di sini jika ada
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap, // <--- HUBUNGKAN KE PARAMETER DI ATAS
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600))
          ],
        ),
      ),
    );
  }
}