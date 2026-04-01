import 'package:flutter/material.dart';

class RentalScreen extends StatelessWidget {
  const RentalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Penyewaan Barang")),
      body: ListView(
        children: const [
          ListTile(
            title: Text("Sewa Proyektor"),
            subtitle: Text("Durasi: 2 Hari"),
            trailing: Text("Rp 200.000"),
          ),
        ],
      ),
    );
  }
}