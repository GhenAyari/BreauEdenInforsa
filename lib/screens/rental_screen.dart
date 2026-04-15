import 'dart:typed_data';
import 'dart:convert'; 
import 'dart:io'; 
import 'dart:async'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:share_plus/share_plus.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:csv/csv.dart'; 
import '../core/colors.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> {
  final _supabase = Supabase.instance.client;

  // --- STATE STREAMS ---
  late Stream<List<Map<String, dynamic>>> _katalogStream;
  late Stream<List<Map<String, dynamic>>> _sedangDisewaStream;
  late Stream<List<Map<String, dynamic>>> _telahSelesaiStream;

  @override
  void initState() {
    super.initState();
    _refreshData(); 
  }

  void _refreshData() {
    setState(() {
      _katalogStream = _supabase.from('products').stream(primaryKey: ['id']).eq('category', 'penyewaan').order('name');
      _sedangDisewaStream = _supabase.from('rentals').stream(primaryKey: ['id']).eq('status', 'Dipinjam').order('created_at', ascending: false);
      _telahSelesaiStream = _supabase.from('rentals').stream(primaryKey: ['id']).eq('status', 'Dikembalikan').order('created_at', ascending: false);
    });
  }

  // ==========================================
  // RUMUS SAKTI: MENGHITUNG TAGIHAN BERDASARKAN JAM
  // ==========================================
  int _hitungTotalTagihan(int hargaPerHari, int qty, String durasiStr) {
    double jam = 24.0; // Default 1 Hari = 24 Jam
    
    // Konversi durasi string menjadi jam
    if (durasiStr == '1 Menit') jam = 1 / 60; // Untuk kebutuhan testing cepat
    else if (durasiStr == '12 Jam') jam = 12.0;
    else if (durasiStr == '24 Jam') jam = 24.0;
    else if (durasiStr == '2 Hari') jam = 48.0;
    else if (durasiStr == '3 Hari') jam = 72.0;
    else if (durasiStr == '1 Minggu') jam = 168.0;

    // Rumus: (Harga / 24 jam) * Jumlah Jam * Quantity
    return ((hargaPerHari / 24) * jam * qty).toInt();
  }

  // ==========================================
  // FUNGSI 1: FORM SEWA & UPLOAD BUKTI SERAH
  // ==========================================
  void _showRentalFormDialog(Map<String, dynamic> product) {
    final namaController = TextEditingController();
    final nikController = TextEditingController();
    final alamatController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    
    String durasiPilihan = '24 Jam';
    final listDurasi = ['1 Menit', '12 Jam', '24 Jam', '2 Hari', '3 Hari', '1 Minggu'];

    Uint8List? selectedImageBytes;
    String? imageExtension;

    final DateTime now = DateTime.now();
    final String tanggalHariIni = "${now.day}-${now.month}-${now.year}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        
        String? errorNama;
        String? errorNik;
        String? errorAlamat;
        String? errorQty;

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

            // HITUNG TAGIHAN SECARA LIVE DI DALAM FORM
            int qtyReal = int.tryParse(qtyController.text.trim()) ?? 0;
            int totalTagihanLive = _hitungTotalTagihan(product['price'], qtyReal, durasiPilihan);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Sewa: ${product['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Stok Tersedia: ${product['stock']} | Tarif: Rp ${product['price']}/hari", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("Tanggal Sewa: $tanggalHariIni", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: namaController, 
                      decoration: InputDecoration(labelText: "Nama Penyewa", prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), errorText: errorNama),
                      onChanged: (_) { if (errorNama != null) setStateDialog(() => errorNama = null); }
                    ),
                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: nikController, 
                      keyboardType: TextInputType.number, 
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                      decoration: InputDecoration(labelText: "NIK (Sesuai KTP)", prefixIcon: const Icon(Icons.badge), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), errorText: errorNik),
                      onChanged: (_) { if (errorNik != null) setStateDialog(() => errorNik = null); }
                    ),
                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: alamatController, 
                      decoration: InputDecoration(labelText: "Alamat Lengkap", prefixIcon: const Icon(Icons.home), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), errorText: errorAlamat),
                      onChanged: (_) { if (errorAlamat != null) setStateDialog(() => errorAlamat = null); }
                    ),
                    const SizedBox(height: 10),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Expanded(
                          flex: 2, 
                          child: TextField(
                            controller: qtyController, 
                            keyboardType: TextInputType.number, 
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                            decoration: InputDecoration(labelText: "Jumlah", prefixIcon: const Icon(Icons.shopping_cart), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), errorText: errorQty),
                            // Update UI setiap kali angka qty diubah
                            onChanged: (_) { setStateDialog(() { errorQty = null; }); }
                          )
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3, 
                          child: DropdownButtonFormField<String>(
                            value: durasiPilihan, 
                            decoration: InputDecoration(labelText: "Durasi Sewa", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), 
                            items: listDurasi.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), 
                            // Update UI setiap kali durasi diganti
                            onChanged: (val) => setStateDialog(() => durasiPilihan = val!)
                          )
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    // UI BARU: PREVIEW TOTAL TAGIHAN
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Tagihan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          Text("Rp $totalTagihanLive", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                        ],
                      ),
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
                    bool isValid = true;
                    int qtySewa = 0;

                    setStateDialog(() {
                      if (namaController.text.trim().isEmpty) { errorNama = "Wajib diisi!"; isValid = false; }
                      if (nikController.text.trim().isEmpty) { errorNik = "Wajib diisi!"; isValid = false; }
                      if (alamatController.text.trim().isEmpty) { errorAlamat = "Wajib diisi!"; isValid = false; }
                      
                      if (qtyController.text.trim().isEmpty) { 
                        errorQty = "Wajib diisi!"; isValid = false; 
                      } else {
                        qtySewa = int.tryParse(qtyController.text.trim()) ?? 0;
                        if (qtySewa <= 0) {
                          errorQty = "Minimal 1!"; isValid = false;
                        } else if (qtySewa > product['stock']) {
                          errorQty = "Melebihi stok!"; isValid = false;
                        }
                      }
                    });

                    if (!isValid) return;

                    if (selectedImageBytes == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wajib melampirkan foto bukti penyerahan!"), backgroundColor: Colors.red)); 
                      return;
                    }
                    
                    Navigator.pop(context); 
                    // Mengirim totalTagihanLive yang sudah dihitung ke database
                    _prosesSewa(product, namaController.text.trim(), nikController.text.trim(), alamatController.text.trim(), qtySewa, durasiPilihan, selectedImageBytes, imageExtension, totalTagihanLive);
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

  Future<void> _prosesSewa(Map<String, dynamic> product, String nama, String nik, String alamat, int qty, String durasi, Uint8List? imgBytes, String? imgExt, int totalTagihan) async {
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
        'total_price': totalTagihan, // Nilai sudah dibagi dengan jam
        'status': 'Dipinjam',
        'rent_proof_url': rentProofUrl
      });
      final newStock = product['stock'] - qty;
      await _supabase.from('products').update({'stock': newStock}).eq('id', product['id']);
      
      if (mounted) {
        Navigator.pop(context); 
        _refreshData(); 
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
        _refreshData(); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Barang telah dikembalikan!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)); }
    }
  }
  
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

    try {
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/Laporan_Penyewaan_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(path)], text: 'Berikut adalah Laporan Penyewaan terbaru.');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengekspor data: $e"), backgroundColor: Colors.red));
      }
    }
  }

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
          _refreshData(); 
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
              stream: _katalogStream,
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
                        subtitle: Text("Stok Tersedia: ${item['stock']}\nTarif: Rp ${item['price']}/hari"),
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

            // TAB 2: DAFTAR SEDANG DISEWA DENGAN TIMER LOKAL
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _sedangDisewaStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada barang yang sedang disewa."));
                
                final rentals = snapshot.data!;
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16), 
                  itemCount: rentals.length,
                  itemBuilder: (context, index) {
                    final rental = rentals[index];
                    return ActiveRentalCard(
                      rental: rental,
                      onReturn: () => _showReturnDialog(rental),
                    );
                  }
                );
              }
            ),

            // TAB 3: TELAH SELESAI
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _telahSelesaiStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada riwayat penyewaan selesai."));
                
                final rentals = snapshot.data!;
                
                return Column(
                  children: [
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


class ActiveRentalCard extends StatefulWidget {
  final Map<String, dynamic> rental;
  final VoidCallback onReturn;

  const ActiveRentalCard({Key? key, required this.rental, required this.onReturn}) : super(key: key);

  @override
  State<ActiveRentalCard> createState() => _ActiveRentalCardState();
}

class _ActiveRentalCardState extends State<ActiveRentalCard> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isOverdue = false;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _parseDurationString(String durationStr) {
    if (durationStr == '1 Menit') return const Duration(minutes: 1);
    if (durationStr == '12 Jam') return const Duration(hours: 12);
    if (durationStr == '24 Jam') return const Duration(hours: 24);
    if (durationStr == '2 Hari') return const Duration(days: 2);
    if (durationStr == '3 Hari') return const Duration(days: 3);
    if (durationStr == '1 Minggu') return const Duration(days: 7);
    return const Duration(hours: 24); 
  }

  void _calculateTime() {
    final createdAt = DateTime.parse(widget.rental['created_at']).toLocal();
    final targetDate = createdAt.add(_parseDurationString(widget.rental['duration']));
    final now = DateTime.now();

    final diff = targetDate.difference(now);

    if (mounted) {
      setState(() {
        if (diff.isNegative) {
          _isOverdue = true;
          _remainingTime = now.difference(targetDate);
        } else {
          _isOverdue = false;
          _remainingTime = diff;
        }
      });
    }
  }

  String _formatDuration(Duration d) {
    String days = d.inDays > 0 ? "${d.inDays} Hari " : "";
    String hours = (d.inHours % 24).toString().padLeft(2, '0');
    String minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$days$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final rental = widget.rental;
    final String tanggalSewa = rental['created_at'].toString().split('T')[0];

    return Card(
      margin: const EdgeInsets.only(bottom: 12), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _isOverdue ? Colors.red.withOpacity(0.5) : Colors.transparent, width: 2)
      ), 
      elevation: 3,
      child: ExpansionTile(
        leading: Icon(
          _isOverdue ? Icons.warning_amber_rounded : Icons.person_pin, 
          color: _isOverdue ? Colors.red : Colors.orange, 
          size: 36
        ),
        title: Text(rental['renter_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${rental['product_name']} (${rental['qty']} pcs)"),
              Text("Tgl Sewa: $tanggalSewa | Durasi: ${rental['duration']}"),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _isOverdue ? Icons.timer_off_outlined : Icons.timer_outlined, 
                    size: 16, 
                    color: _isOverdue ? Colors.red : Colors.grey[700]
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _isOverdue 
                        ? "Habis (Terlambat: ${_formatDuration(_remainingTime)})" 
                        : "Sisa Waktu: ${_formatDuration(_remainingTime)}",
                      style: TextStyle(
                        color: _isOverdue ? Colors.red : Colors.grey[800], 
                        fontWeight: _isOverdue ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
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
                    onPressed: widget.onReturn,
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
}