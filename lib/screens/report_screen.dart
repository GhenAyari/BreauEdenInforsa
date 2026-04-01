import 'package:flutter/material.dart';
import 'package:ui_pa_pab_lanjutan/core/colors.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Keuangan"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Card(
              child: ListTile(
                title: Text("Total Pendapatan"),
                trailing: Text("Rp 145.230.000"),
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                title: Text("Total Pengeluaran"),
                trailing: Text("Rp 82.450.000"),
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                title: Text("Laba Bersih"),
                trailing: Text("Rp 62.780.000"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}