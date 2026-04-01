import 'package:flutter/material.dart';
import '../core/colors.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaksi Penjualan"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, i) {
          return Card(
            child: ListTile(
              title: Text("Produk ${i + 1}"),
              subtitle: const Text("Rp 50.000"),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text("Tambah"),
              ),
            ),
          );
        },
      ),
    );
  }
}