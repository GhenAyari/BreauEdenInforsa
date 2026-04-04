import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. Tambahkan import ini
import '../core/colors.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // Inisialisasi client Supabase
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaksi Penjualan"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      // 2. Ganti body lama dengan StreamBuilder
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // === LANGKAH 3 DITARUH DI SINI ===
        stream: _supabase
            .from('products')
            .stream(primaryKey: ['id'])
            .eq('category', 'store_stand') // Hanya ambil produk toko/stand
            .order('name'),
        // ================================
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada produk tersedia di toko."));
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final item = products[i];
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: item['image_url'] != null 
                        ? NetworkImage(item['image_url']) 
                        : null,
                    child: item['image_url'] == null 
                        ? const Icon(Icons.inventory_2) 
                        : null,
                  ),
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Rp ${item['price']} | Stok: ${item['stock']}"),
                  trailing: ElevatedButton(
                    // Tombol otomatis mati (disabled) jika stok habis
                    onPressed: item['stock'] > 0 ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${item['name']} ditambah ke keranjang")),
                      );
                    } : null,
                    child: const Text("Tambah"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}