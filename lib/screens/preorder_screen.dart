import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/colors.dart';

class PreOrderScreen extends StatefulWidget {
  const PreOrderScreen({super.key});

  @override
  State<PreOrderScreen> createState() => _PreOrderScreenState();
}

class _PreOrderScreenState extends State<PreOrderScreen> {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // FUNGSI 1: FORM TAMBAH / EDIT PO
  // ==========================================
  void _showPoFormDialog({Map<String, dynamic>? existingPo}) {
    final isEditing = existingPo != null;

    final customerController = TextEditingController(text: isEditing ? existingPo['customer_name'] : '');
    // FITUR BARU: Controller Telepon dan Tanggal
    final phoneController = TextEditingController(text: isEditing ? existingPo['phone_number'] : '');
    final dateController = TextEditingController(text: isEditing ? existingPo['order_date'] : '');
    
    final itemController = TextEditingController(text: isEditing ? existingPo['item_name'] : '');
    final qtyController = TextEditingController(text: isEditing ? existingPo['qty'].toString() : '1');
    final priceController = TextEditingController(text: isEditing ? existingPo['total_price'].toString() : '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? "Edit Pre-Order" : "Buat Pre-Order Baru", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: customerController, decoration: InputDecoration(labelText: "Nama Pemesan", prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 10),
                
                // FITUR BARU: Input No HP
                TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "No. WhatsApp/Telepon", prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 10),
                
                // FITUR BARU: Input Tanggal Manual
                TextField(controller: dateController, decoration: InputDecoration(labelText: "Tanggal PO (Manual)", hintText: "Misal: 5 April 2026", prefixIcon: const Icon(Icons.calendar_today), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 10),

                TextField(controller: itemController, decoration: InputDecoration(labelText: "Nama Barang (Misal: PDH Ukuran L)", prefixIcon: const Icon(Icons.shopping_bag), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(flex: 2, child: TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Jumlah", prefixIcon: const Icon(Icons.format_list_numbered), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                    const SizedBox(width: 10),
                    Expanded(flex: 3, child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Total Bayar (Rp)", prefixIcon: const Icon(Icons.payments), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                // Validasi bertambah
                if (customerController.text.isEmpty || phoneController.text.isEmpty || dateController.text.isEmpty || itemController.text.isEmpty || qtyController.text.isEmpty || priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua kolom wajib diisi!"), backgroundColor: Colors.red));
                  return;
                }

                Navigator.pop(context); // Tutup Form
                _savePoData(
                  id: isEditing ? existingPo['id'] : null,
                  customer: customerController.text,
                  phone: phoneController.text,
                  orderDate: dateController.text,
                  item: itemController.text,
                  qty: int.tryParse(qtyController.text) ?? 1,
                  price: num.tryParse(priceController.text) ?? 0,
                );
              },
              child: Text(isEditing ? "Simpan Perubahan" : "Buat Pre-Order"),
            )
          ],
        );
      }
    );
  }

  Future<void> _savePoData({dynamic id, required String customer, required String phone, required String orderDate, required String item, required int qty, required num price}) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final poData = {
        'customer_name': customer,
        'phone_number': phone,
        'order_date': orderDate,
        'item_name': item,
        'qty': qty,
        'total_price': price,
      };

      if (id != null) {
        await _supabase.from('preorders').update(poData).eq('id', id); // Update
      } else {
        await _supabase.from('preorders').insert(poData); // Insert Baru
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Pre-Order berhasil disimpan!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // ==========================================
  // FUNGSI 2: UBAH STATUS JADI DITERIMA
  // ==========================================
  Future<void> _markAsReceived(dynamic id, String customerName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Selesai"),
        content: Text("Tandai pesanan atas nama $customerName sudah diterima oleh pemesan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog konfirmasi
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
              try {
                await _supabase.from('preorders').update({'status': 'Sudah Diterima'}).eq('id', id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pesanan telah diselesaikan!"), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Sudah Diterima"),
          )
        ],
      )
    );
  }

  // ==========================================
  // FUNGSI 3: HAPUS PO
  // ==========================================
  Future<void> _deletePo(dynamic id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Pesanan?"),
        content: const Text("Data ini akan dihapus secara permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context); 
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
              try {
                await _supabase.from('preorders').delete().eq('id', id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pesanan dihapus!"), backgroundColor: Colors.red));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Hapus"),
          )
        ],
      )
    );
  }

  // ==========================================
  // RENDER UI: 2 TABS
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Manajemen Pre-Order"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Aktif (Belum Diterima)"),
              Tab(text: "Riwayat Selesai"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            
            // TAB 1: PO AKTIF
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('preorders').stream(primaryKey: ['id']).eq('status', 'Belum Diterima').order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada data Pre-Order aktif."));
                
                final pos = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
                  itemCount: pos.length,
                  itemBuilder: (context, index) {
                    final po = pos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade200, width: 1)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.hourglass_bottom, color: Colors.white)),
                        title: Text(po['customer_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            // Menampilkan Telepon dan Tanggal
                            Text("Telp: ${po['phone_number'] ?? '-'} | Tgl: ${po['order_date'] ?? '-'}"),
                            Text("${po['item_name']} (${po['qty']} pcs)"),
                            const SizedBox(height: 5),
                            Text("Total Bayar: Rp ${po['total_price']}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showPoFormDialog(existingPo: po)),
                            IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 30), onPressed: () => _markAsReceived(po['id'], po['customer_name'])),
                          ],
                        ),
                      ),
                    );
                  }
                );
              }
            ),

            // TAB 2: RIWAYAT SELESAI
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('preorders').stream(primaryKey: ['id']).eq('status', 'Sudah Diterima').order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada riwayat Pre-Order yang selesai."));
                
                final pos = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pos.length,
                  itemBuilder: (context, index) {
                    final po = pos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.done_all, color: Colors.white)),
                        title: Text(po['customer_name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("Telp: ${po['phone_number'] ?? '-'}"),
                            Text("${po['item_name']} (${po['qty']} pcs)"),
                            Text("Tgl Order: ${po['order_date'] ?? '-'}"),
                          ],
                        ),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deletePo(po['id'])),
                      ),
                    );
                  }
                );
              }
            ),

          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showPoFormDialog(),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("Buat PO Baru"),
        ),
      ),
    );
  }
}