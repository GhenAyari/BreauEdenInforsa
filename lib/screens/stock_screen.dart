import 'package:flutter/material.dart';
import '../core/colors.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manajemen Stok"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (_, index) {
          return Card(
            child: ListTile(
              title: Text("Barang ${index + 1}"),
              subtitle: const Text("Stok: 25"),
              trailing: const Icon(Icons.edit),
            ),
          );
        }
      ),
    );
  }
}