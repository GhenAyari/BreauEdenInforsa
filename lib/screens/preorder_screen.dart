import 'package:flutter/material.dart';

class PreOrderScreen extends StatelessWidget {
  const PreOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pre-Order")),
      body: ListView(
        children: const [
          ListTile(
            title: Text("PO Merchandise INFORSA"),
            subtitle: Text("Status: Menunggu Pembayaran"),
            trailing: Text("Rp 150.000"),
          ),
        ],
      ),
    );
  }
}