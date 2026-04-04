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

  // FUNGSI: Menampilkan Form Sewa (Pop-up)
  void _showRentalFormDialog(Map<String, dynamic> product) {
    final namaController = TextEditingController();
    final nikController = TextEditingController();
    final alamatController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    String durasiPilihan = '24 Jam';

    final listDurasi = ['12 Jam', '24 Jam', '2 Hari', '3 Hari', '1 Minggu'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Sewa: ${product['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Stok Tersedia: ${product['stock']} | Harga Sewa: Rp ${product['price']}", 
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: namaController,
                      decoration: InputDecoration(labelText: "Nama Penyewa", prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: nikController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "NIK (Sesuai KTP)", prefixIcon: const Icon(Icons.badge), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: alamatController,
                      decoration: InputDecoration(labelText: "Alamat Lengkap", prefixIcon: const Icon(Icons.home), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 10),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: "Jumlah", prefixIcon: const Icon(Icons.shopping_cart), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: durasiPilihan,
                            decoration: InputDecoration(labelText: "Durasi Sewa", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                            items: listDurasi.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (val) => setStateDialog(() => durasiPilihan = val!),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    // Validasi Kosong
                    if (namaController.text.isEmpty || nikController.text.isEmpty || alamatController.text.isEmpty || qtyController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua data wajib diisi!"), backgroundColor: Colors.red));
                      return;
                    }

                    // Validasi Stok
                    int qtySewa = int.tryParse(qtyController.text) ?? 0;
                    if (qtySewa <= 0 || qtySewa > product['stock']) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jumlah tidak valid atau melebihi stok!"), backgroundColor: Colors.red));
                      return;
                    }

                    Navigator.pop(context); // Tutup form
                    _prosesSewa(product, namaController.text, nikController.text, alamatController.text, qtySewa, durasiPilihan);
                  },
                  child: const Text("Simpan & Sewakan"),
                )
              ],
            );
          }
        );
      }
    );
  }

  // FUNGSI: Mengirim data sewa ke database dan mengurangi stok
  Future<void> _prosesSewa(Map<String, dynamic> product, String nama, String nik, String alamat, int qty, String durasi) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      // 1. Catat ke tabel rentals
      await _supabase.from('rentals').insert({
        'product_id': product['id'],
        'product_name': product['name'],
        'renter_name': nama,
        'renter_nik': nik,
        'renter_address': alamat,
        'qty': qty,
        'duration': durasi,
        'total_price': (product['price'] * qty), 
        'status': 'Dipinjam'
      });

      // 2. Kurangi stok barang asli
      final newStock = product['stock'] - qty;
      await _supabase.from('products').update({'stock': newStock}).eq('id', product['id']);

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Barang berhasil disewakan!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // FUNGSI: Mengembalikan barang (Status berubah, stok balik)
  Future<void> _prosesKembali(Map<String, dynamic> rental) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      // 1. Ubah status di tabel rentals
      await _supabase.from('rentals').update({'status': 'Dikembalikan'}).eq('id', rental['id']);

      // 2. Cek stok terakhir barang tersebut dan kembalikan stoknya
      if (rental['product_id'] != null) {
        final productData = await _supabase.from('products').select('stock').eq('id', rental['product_id']).single();
        final currentStock = productData['stock'] as int;
        final newStock = currentStock + (rental['qty'] as int);

        await _supabase.from('products').update({'stock': newStock}).eq('id', rental['product_id']);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Barang telah dikembalikan ke stok!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Penyewaan Barang"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Katalog Sewa"),
              Tab(text: "Sedang Disewa"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            
            // TAB 1: KATALOG BARANG (Menampilkan barang dengan kategori penyewaan)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('products').stream(primaryKey: ['id']).eq('category', 'penyewaan').order('name'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada barang penyewaan."));

                final products = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final item = products[index];
                    final bool isHabis = item['stock'] <= 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          backgroundImage: item['image_url'] != null ? NetworkImage(item['image_url']) : null,
                          child: item['image_url'] == null ? const Icon(Icons.handshake, color: Colors.grey) : null,
                        ),
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Stok Tersedia: ${item['stock']}\nHarga Sewa: Rp ${item['price']}"),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isHabis ? Colors.grey : AppColors.primary, 
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          onPressed: isHabis ? null : () => _showRentalFormDialog(item),
                          child: Text(isHabis ? "Habis" : "Sewakan"),
                        ),
                      ),
                    );
                  }
                );
              }
            ),

            // TAB 2: DAFTAR SEDANG DISEWA (Menarik data dari tabel rentals)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('rentals').stream(primaryKey: ['id']).eq('status', 'Dipinjam').order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada barang yang sedang disewa."));

                final rentals = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rentals.length,
                  itemBuilder: (context, index) {
                    final rental = rentals[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ExpansionTile(
                        leading: const Icon(Icons.person_pin, color: Colors.orange, size: 36),
                        title: Text(rental['renter_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${rental['product_name']} (${rental['qty']} pcs) - ${rental['duration']}"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Detail Identitas Penyewa:", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text("NIK KTP: ${rental['renter_nik']}"),
                                Text("Alamat: ${rental['renter_address']}"),
                                const Divider(),
                                Text("Total Tagihan: Rp ${rental['total_price']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Konfirmasi Pengembalian"),
                                          content: Text("Yakin ingin menyelesaikan sewa dan mengembalikan ${rental['qty']} stok ${rental['product_name']}?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                                            ElevatedButton(onPressed: () { Navigator.pop(context); _prosesKembali(rental); }, child: const Text("Kembalikan")),
                                          ],
                                        )
                                      );
                                    },
                                    icon: const Icon(Icons.assignment_return),
                                    label: const Text("Tandai Dikembalikan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }
                );
              }
            ),

          ],
        ),
      ),
    );
  }
}