import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/colors.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  // Pindahkan pemanggilan client ke getter agar selalu fresh
  SupabaseClient get _supabase => Supabase.instance.client;
  
  // Stream untuk mendengarkan perubahan data
  late final Stream<List<Map<String, dynamic>>> _productsStream;

  @override
  void initState() {
    super.initState();
    // Inisialisasi stream di dalam initState
    _productsStream = _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true);
  }

  // Fungsi untuk menampilkan Pop-up Form (Bisa untuk Tambah & Edit)
  Future<void> _showFormDialog({Map<String, dynamic>? product}) async {
    final isEditing = product != null; 
    
    final nameController = TextEditingController(text: isEditing ? product['name'] : '');
    final priceController = TextEditingController(text: isEditing ? product['price'].toString() : '');
    final stockController = TextEditingController(text: isEditing ? product['stock'].toString() : '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Barang' : 'Tambah Barang Baru', 
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Barang', prefixIcon: Icon(Icons.inventory_2_outlined)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga (Rp)', prefixIcon: Icon(Icons.attach_money)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah Stok', prefixIcon: Icon(Icons.numbers)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Validasi
                if (nameController.text.isEmpty || priceController.text.isEmpty || stockController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final name = nameController.text;
                final price = num.tryParse(priceController.text) ?? 0;
                final stock = int.tryParse(stockController.text) ?? 0;

                try {
                  if (isEditing) {
                    // Pakai _supabase langsung (yang sekarang berupa getter)
                    await _supabase.from('products').update({
                      'name': name,
                      'price': price,
                      'stock': stock,
                    }).eq('id', product['id']);
                  } else {
                    await _supabase.from('products').insert({
                      'name': name,
                      'price': price,
                      'stock': stock,
                    });
                  }
                  
                  if (mounted) {
                    Navigator.pop(context); // Tutup dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Barang berhasil diubah!' : 'Barang baru ditambahkan!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  print("Error Supabase: $e"); // Cetak error di console untuk debugging
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Terjadi kesalahan, cek koneksi internet.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi tambahan untuk menghapus barang
  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: const Text('Yakin ingin menghapus barang ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );

    if (confirm == true) {
      try {
        await _supabase.from('products').delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang berhasil dihapus'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
         print("Error hapus: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manajemen Stok"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada data barang.'));
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (_, index) {
              final product = products[index];
              
              return Card(
                child: ListTile(
                  title: Text(
                    product['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Stok: ${product['stock']} | Rp ${product['price']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () => _showFormDialog(product: product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteProduct(product['id']),
                      ),
                    ],
                  ),
                ),
              );
            }
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(), 
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}