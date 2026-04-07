import 'dart:typed_data';
import 'dart:convert'; // IMPORT BARU UNTUK CSV
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:csv/csv.dart'; // IMPORT BARU UNTUK CSV
import '../core/colors.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // FUNGSI 1: FORM SEWA & UPLOAD BUKTI SERAH
  // ==========================================
  void _showRentalFormDialog(Map<String, dynamic> product) {
    final namaController = TextEditingController();
    final nikController = TextEditingController();
    final alamatController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    String durasiPilihan = '24 Jam';
    final listDurasi = ['12 Jam', '24 Jam', '2 Hari', '3 Hari', '1 Minggu'];

    Uint8List? selectedImageBytes;
    String? imageExtension;

    final DateTime now = DateTime.now();
    final String tanggalHariIni = "${now.day}-${now.month}-${now.year}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickImage(ImageSource source) async {
              try {
                final ImagePicker localPicker = ImagePicker(); 
                final XFile? image = await localPicker.pickImage(source: source);
                
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setStateDialog(() {
                    selectedImageBytes = bytes;
                    imageExtension = image.name.contains('.') ? image.name.split('.').last : 'png';
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal membuka Kamera/Galeri: $e"), backgroundColor: Colors.red));
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Sewa: ${product['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Stok Tersedia: ${product['stock']} | Harga Sewa: Rp ${product['price']}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("Tanggal Sewa: $tanggalHariIni", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    TextField(controller: namaController, decoration: InputDecoration(labelText: "Nama Penyewa", prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 10),
                    TextField(controller: nikController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "NIK (Sesuai KTP)", prefixIcon: const Icon(Icons.badge), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 10),
                    TextField(controller: alamatController, decoration: InputDecoration(labelText: "Alamat Lengkap", prefixIcon: const Icon(Icons.home), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(flex: 2, child: TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Jumlah", prefixIcon: const Icon(Icons.shopping_cart), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                        const SizedBox(width: 10),
                        Expanded(flex: 3, child: DropdownButtonFormField<String>(value: durasiPilihan, decoration: InputDecoration(labelText: "Durasi Sewa", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), items: listDurasi.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (val) => setStateDialog(() => durasiPilihan = val!))),
                      ],
                    ),
                    const Divider(height: 30),
                    const Text("Foto Bukti Penyerahan:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (selectedImageBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12), 
                        child: Image.memory(selectedImageBytes!, height: 120, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Padding(padding: EdgeInsets.all(10), child: Text("Format gambar tidak didukung", style: TextStyle(color: Colors.red))))
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(child: OutlinedButton.icon(onPressed: () => pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt, size: 18), label: const Text("Kamera"))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton.icon(onPressed: () => pickImage(ImageSource.gallery), icon: const Icon(Icons.image, size: 18), label: const Text("Galeri"))),
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
                    if (namaController.text.isEmpty || nikController.text.isEmpty || alamatController.text.isEmpty || qtyController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua data wajib diisi!"), backgroundColor: Colors.red)); return;
                    }
                    if (selectedImageBytes == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wajib melampirkan foto bukti penyerahan!"), backgroundColor: Colors.red)); return;
                    }
                    int qtySewa = int.tryParse(qtyController.text) ?? 0;
                    if (qtySewa <= 0 || qtySewa > product['stock']) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jumlah tidak valid atau melebihi stok!"), backgroundColor: Colors.red)); return;
                    }
                    Navigator.pop(context); 
                    _prosesSewa(product, namaController.text, nikController.text, alamatController.text, qtySewa, durasiPilihan, selectedImageBytes, imageExtension);
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

  Future<void> _prosesSewa(Map<String, dynamic> product, String nama, String nik, String alamat, int qty, String durasi, Uint8List? imgBytes, String? imgExt) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      String? rentProofUrl;
      if (imgBytes != null && imgExt != null) {
        final fileName = 'rent_${DateTime.now().millisecondsSinceEpoch}.$imgExt';
        await _supabase.storage.from('rental_proofs').uploadBinary(fileName, imgBytes);
        rentProofUrl = _supabase.storage.from('rental_proofs').getPublicUrl(fileName);
      }
      await _supabase.from('rentals').insert({
        'product_id': product['id'],
        'product_name': product['name'],
        'renter_name': nama,
        'renter_nik': nik,
        'renter_address': alamat,
        'qty': qty,
        'duration': durasi,
        'total_price': (product['price'] * qty), 
        'status': 'Dipinjam',
        'rent_proof_url': rentProofUrl
      });
      final newStock = product['stock'] - qty;
      await _supabase.from('products').update({'stock': newStock}).eq('id', product['id']);
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Barang berhasil disewakan!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)); }
    }
  }


  // ==========================================
  // FUNGSI 2: FORM KEMBALI & UPLOAD BUKTI KEMBALI
  // ==========================================
  void _showReturnDialog(Map<String, dynamic> rental) {
    Uint8List? selectedImageBytes;
    String? imageExtension;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickImage(ImageSource source) async {
              try {
                final ImagePicker localPicker = ImagePicker(); 
                final XFile? image = await localPicker.pickImage(source: source);
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setStateDialog(() {
                    selectedImageBytes = bytes;
                    imageExtension = image.name.contains('.') ? image.name.split('.').last : 'png';
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal membuka Kamera/Galeri: $e"), backgroundColor: Colors.red));
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Konfirmasi Pengembalian", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Penyewa: ${rental['renter_name']}\nBarang: ${rental['product_name']} (${rental['qty']} pcs)"),
                    const Divider(height: 30),
                    const Text("Foto Bukti Dikembalikan:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (selectedImageBytes != null) ...[
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(selectedImageBytes!, height: 120, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Padding(padding: EdgeInsets.all(10), child: Text("Format gambar tidak didukung", style: TextStyle(color: Colors.red))))),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(child: OutlinedButton.icon(onPressed: () => pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt, size: 18), label: const Text("Kamera"))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton.icon(onPressed: () => pickImage(ImageSource.gallery), icon: const Icon(Icons.image, size: 18), label: const Text("Galeri"))),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    if (selectedImageBytes == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wajib melampirkan foto bukti pengembalian!"), backgroundColor: Colors.red)); return; }
                    Navigator.pop(context); 
                    _prosesKembali(rental, selectedImageBytes!, imageExtension);
                  },
                  child: const Text("Selesaikan & Kembalikan"),
                )
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _prosesKembali(Map<String, dynamic> rental, Uint8List imgBytes, String? imgExt) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      String? returnProofUrl;
      final fileName = 'return_${DateTime.now().millisecondsSinceEpoch}.$imgExt';
      await _supabase.storage.from('rental_proofs').uploadBinary(fileName, imgBytes);
      returnProofUrl = _supabase.storage.from('rental_proofs').getPublicUrl(fileName);

      await _supabase.from('rentals').update({'status': 'Dikembalikan', 'return_proof_url': returnProofUrl}).eq('id', rental['id']);

      if (rental['product_id'] != null) {
        final productData = await _supabase.from('products').select('stock').eq('id', rental['product_id']).single();
        final currentStock = productData['stock'] as int;
        final newStock = currentStock + (rental['qty'] as int);
        await _supabase.from('products').update({'stock': newStock}).eq('id', rental['product_id']);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Barang telah dikembalikan!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)); }
    }
  }

  // ==========================================
  // FUNGSI BARU 3: EKSPOR CSV & HAPUS RIWAYAT
  // ==========================================
  Future<void> _exportRentalsToCSV(List<Map<String, dynamic>> rentals) async {
    List<List<dynamic>> rows = [];
    rows.add(['LAPORAN RIWAYAT PENYEWAAN BARANG']);
    rows.add(['Diekspor pada', DateTime.now().toString().split('.')[0]]);
    rows.add([]);
    rows.add(['Nama Penyewa', 'NIK KTP', 'Alamat', 'Nama Barang', 'Jumlah (Qty)', 'Durasi', 'Total Pendapatan', 'Tanggal Sewa', 'Link Bukti Diserahkan', 'Link Bukti Dikembalikan']);

    double grandTotal = 0;
    for (var rental in rentals) {
      grandTotal += (rental['total_price'] ?? 0);
      rows.add([
        rental['renter_name'],
        rental['renter_nik'],
        rental['renter_address'],
        rental['product_name'],
        rental['qty'],
        rental['duration'],
        rental['total_price'],
        rental['created_at'].toString().split('T')[0],
        rental['rent_proof_url'] ?? '-',
        rental['return_proof_url'] ?? '-',
      ]);
    }
    rows.add([]);
    rows.add(['GRAND TOTAL PENDAPATAN SEWA', grandTotal]);

    String csvData = const ListToCsvConverter().convert(rows);

    // --- BAGIAN BARU: SISTEM SHARE ANDROID ---
    try {
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/Laporan_Penyewaan_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      // Memunculkan menu Share di HP
      await Share.shareXFiles([XFile(path)], text: 'Berikut adalah Laporan Penyewaan terbaru.');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengekspor data: $e"), backgroundColor: Colors.red));
      }
    }
  } // <-- Ini tutup kurung fungsi _exportRentalsToCSV

  Future<void> _deleteRentalHistory(dynamic id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Riwayat?"),
        content: const Text("Yakin ingin menghapus riwayat sewa ini secara permanen? Data yang dihapus tidak akan masuk ke Laporan CSV."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      try {
        await _supabase.from('rentals').delete().eq('id', id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Riwayat berhasil dihapus"), backgroundColor: Colors.red));
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }


  // ==========================================
  // RENDER UI: 3 TABS
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
              Tab(text: "Telah Selesai"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            
            // TAB 1: KATALOG BARANG
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('products').stream(primaryKey: ['id']).eq('category', 'penyewaan').order('name'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada barang penyewaan."));
                final products = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16), itemCount: products.length,
                  itemBuilder: (context, index) {
                    final item = products[index];
                    final bool isHabis = item['stock'] <= 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.grey[200], backgroundImage: item['image_url'] != null ? NetworkImage(item['image_url']) : null, child: item['image_url'] == null ? const Icon(Icons.handshake, color: Colors.grey) : null),
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Stok Tersedia: ${item['stock']}\nHarga Sewa: Rp ${item['price']}"),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: isHabis ? Colors.grey : AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          onPressed: isHabis ? null : () => _showRentalFormDialog(item),
                          child: Text(isHabis ? "Habis" : "Sewakan"),
                        ),
                      ),
                    );
                  }
                );
              }
            ),

            // TAB 2: DAFTAR SEDANG DISEWA
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('rentals').stream(primaryKey: ['id']).eq('status', 'Dipinjam').order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada barang yang sedang disewa."));
                final rentals = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16), itemCount: rentals.length,
                  itemBuilder: (context, index) {
                    final rental = rentals[index];
                    final String tanggalSewa = rental['created_at'].toString().split('T')[0];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3,
                      child: ExpansionTile(
                        leading: const Icon(Icons.person_pin, color: Colors.orange, size: 36),
                        title: Text(rental['renter_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${rental['product_name']} (${rental['qty']} pcs)\nTgl Sewa: $tanggalSewa | Durasi: ${rental['duration']}"),
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
                                if (rental['rent_proof_url'] != null) ...[
                                  const Text("Bukti Penyerahan Awal:", style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(rental['rent_proof_url'], height: 150, width: double.infinity, fit: BoxFit.cover)),
                                  const SizedBox(height: 10),
                                ],
                                Text("Total Tagihan: Rp ${rental['total_price']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
                                    onPressed: () => _showReturnDialog(rental),
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

            // TAB 3: TELAH SELESAI (DENGAN FITUR DOWNLOAD & HAPUS)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('rentals').stream(primaryKey: ['id']).eq('status', 'Dikembalikan').order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada riwayat penyewaan selesai."));
                
                final rentals = snapshot.data!;
                
                return Column(
                  children: [
                    // TOMBOL EXPORT CSV DI BAGIAN ATAS
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          onPressed: () => _exportRentalsToCSV(rentals),
                          icon: const Icon(Icons.download),
                          label: const Text("Ekspor Laporan Selesai (CSV)", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16), 
                        itemCount: rentals.length,
                        itemBuilder: (context, index) {
                          final rental = rentals[index];
                          final String tanggalSewa = rental['created_at'].toString().split('T')[0];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2,
                            child: ExpansionTile(
                              leading: const Icon(Icons.check_circle, color: Colors.green, size: 36),
                              title: Text(rental['renter_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${rental['product_name']} | Tgl Sewa: $tanggalSewa"),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("NIK KTP: ${rental['renter_nik']}\nAlamat: ${rental['renter_address']}\nDurasi: ${rental['duration']}\nPendapatan: Rp ${rental['total_price']}"),
                                      const Divider(height: 30),
                                      const Text("Dokumentasi Foto:", style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const Text("Saat Diserahkan", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                const SizedBox(height: 5),
                                                if (rental['rent_proof_url'] != null)
                                                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(rental['rent_proof_url'], height: 100, fit: BoxFit.cover))
                                                else const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const Text("Saat Dikembalikan", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                const SizedBox(height: 5),
                                                if (rental['return_proof_url'] != null)
                                                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(rental['return_proof_url'], height: 100, fit: BoxFit.cover))
                                                else const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      // TOMBOL HAPUS RIWAYAT
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                          onPressed: () => _deleteRentalHistory(rental['id']),
                                          icon: const Icon(Icons.delete_outline),
                                          label: const Text("Hapus Riwayat Ini"),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        }
                      ),
                    ),
                  ],
                );
              }
            ),

          ],
        ),
      ),
    );
  }
}