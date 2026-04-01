import 'package:flutter/material.dart';
import '../core/colors.dart';

class ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const ActionCard({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {},
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