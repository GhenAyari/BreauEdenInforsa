import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/colors.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> {
  final _supabase = Supabase.instance.client;

  // Fungsi untuk mengganti status barang sewaan
  Future<void> _toggleRentalStatus(String id, String currentStatus) async {
    final newStatus = currentStatus == 'Tersedia' ? 'Sedang Disewa' : 'Tersedia';
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      await _supabase.from('products').update({'rental_status': newStatus}).eq('id', id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Penyewaan Barang"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      // StreamBuilder narik data khusus yang kategorinya 'penyewaan'
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('products').stream(primaryKey: ['id']).eq('category', 'penyewaan').order('name'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada barang penyewaan di stok."));
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final item = products[index];
              final isRented = item['rental_status'] == 'Sedang Disewa';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage: item['image_url'] != null ? NetworkImage(item['image_url']) : null,
                    child: item['image_url'] == null ? const Icon(Icons.handshake, color: Colors.grey) : null,
                  ),
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Harga Sewa: Rp ${item['price']}\nStatus: ${item['rental_status'] ?? 'Tersedia'}"),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRented ? Colors.orange : AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _toggleRentalStatus(item['id'], item['rental_status'] ?? 'Tersedia'),
                    child: Text(isRented ? "Kembalikan" : "Sewakan"),
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}