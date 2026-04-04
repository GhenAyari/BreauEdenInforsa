import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // IMPORT BARU
import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';
import '../core/colors.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker(); // INISIALISASI PICKER

  // --- STATE SESI & KERANJANG ---
  bool _isSessionOpen = false;
  String? _currentSessionId;
  String _operatorName = "";
  String _standName = ""; 
  double _modalAwal = 0;

  bool _isCartExpanded = false;
  List<Map<String, dynamic>> _cart = [];

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  // --- FUNGSI DATABASE (SUPABASE) ---

  Future<void> _checkActiveSession() async {
    try {
      final data = await _supabase.from('sessions').select().eq('status', 'open').order('created_at', ascending: false).limit(1);
      if (data.isNotEmpty && mounted) {
        setState(() {
          _isSessionOpen = true;
          _currentSessionId = data[0]['id'];
          _operatorName = data[0]['operator_name'];
          _standName = data[0]['stand_name'] ?? 'Stand Reguler'; 
          _modalAwal = data[0]['modal_awal'].toDouble();
        });
      }
    } catch (e) {
      print("Error cek sesi: $e");
    }
  }

  Future<void> _openSession(String operator, double modal, String standName) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await _supabase.from('sessions').insert({
        'operator_name': operator,
        'modal_awal': modal,
        'stand_name': standName, 
        'status': 'open'
      }).select('id').single();

      if (mounted) {
        setState(() {
          _isSessionOpen = true;
          _currentSessionId = response['id'];
          _operatorName = operator;
          _standName = standName;
          _modalAwal = modal;
          _cart.clear();
          _isCartExpanded = false;
        });
        Navigator.pop(context); 
        Navigator.pop(context); 
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal buka stand: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _closeSession() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      await _supabase.from('sessions').update({
        'status': 'closed',
        'closed_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentSessionId!);

      if (mounted) {
        setState(() {
          _isSessionOpen = false;
          _currentSessionId = null;
          _cart.clear();
          _isCartExpanded = false;
        });
        Navigator.pop(context); 
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stand berhasil ditutup!")));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal tutup stand: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Riwayat?"),
        content: const Text("Yakin ingin menghapus riwayat sesi ini? Semua data transaksi di dalamnya juga akan ikut terhapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Hapus", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      try {
        await _supabase.from('sessions').delete().eq('id', sessionId);
        
        if (mounted) {
          Navigator.pop(context); 
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Riwayat sesi berhasil dihapus"), backgroundColor: Colors.red)
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  // FUNGSI DIPERBARUI: Menerima file foto bukti (jika ada)
  Future<void> _prosesBayarKeDatabase(String metodePembayaran, {Uint8List? proofBytes, String? fileExt}) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      String? proofUrl;

      // Jika ada file bukti (QRIS), upload dulu ke Storage
      if (proofBytes != null && fileExt != null) {
        final fileName = 'qris_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await _supabase.storage.from('qris_proof').uploadBinary(fileName, proofBytes);
        proofUrl = _supabase.storage.from('qris_proof').getPublicUrl(fileName);
      }

      final trxResponse = await _supabase.from('transactions').insert({
        'session_id': _currentSessionId,
        'payment_method': metodePembayaran,
        'total_amount': _cartTotal,
        'proof_url': proofUrl, // Simpan URL ke database
      }).select('id').single();

      final transactionId = trxResponse['id'];

      for (var item in _cart) {
        await _supabase.from('transaction_items').insert({
          'transaction_id': transactionId,
          'product_id': item['id'],
          'product_name': item['name'],
          'qty': item['qty'],
          'price': item['price'],
          'modal': item['modal'] ?? 0, // TITIK BEDAH 1: Simpan modal saat bayar
          'total_price': item['qty'] * item['price'],
        });

        final newStock = item['stock'] - item['qty'];
        await _supabase.from('products').update({'stock': newStock}).eq('id', item['id']);
      }

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pembayaran $metodePembayaran Berhasil!"), backgroundColor: AppColors.success));
        setState(() {
          _cart.clear();
          _isCartExpanded = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memproses: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- FUNGSI EKSPOR CSV (TITIK BEDAH 2) ---
  Future<void> _exportToCSV(Map<String, dynamic> session) async {
    List<List<dynamic>> rows = [];

    rows.add(['LAPORAN PENJUALAN STAND INFORSA']);
    rows.add(['Nama Stand', session['stand_name'] ?? 'Stand Reguler']);
    rows.add(['Tanggal', session['closed_at'].toString().split('T')[0]]);
    rows.add(['Penjaga Shift', session['operator_name']]);
    rows.add(['Modal Awal (Tunai)', session['modal_awal']]);
    rows.add([]); 

    // Header Tabel ditambah Kolom Modal
    rows.add(['Nama Barang', 'Jumlah (Qty)', 'Harga Satuan', 'Modal Satuan', 'Total Harga', 'Metode Bayar', 'Link Bukti QRIS']);

    final transactions = session['transactions'] as List;
    double totalTunai = 0;
    double totalQRIS = 0;
    double grandTotalPemasukan = 0;
    double grandTotalModal = 0;

    for (var t in transactions) {
      if (t['payment_method'].toString().contains('Tunai')) {
        totalTunai += t['total_amount'];
      } else if (t['payment_method'].toString().contains('QRIS')) {
        totalQRIS += t['total_amount'];
      }
      grandTotalPemasukan += t['total_amount'];

      for (var item in t['transaction_items']) {
        double modalItem = (item['modal'] ?? 0).toDouble(); // Ambil nilai modal dari database
        grandTotalModal += (modalItem * item['qty']); // Hitung total modal terpakai

        rows.add([
          item['product_name'],
          item['qty'],
          item['price'],
          modalItem, // Masukkan Modal Satuan ke baris CSV
          item['total_price'],
          t['payment_method'],
          t['proof_url'] ?? '-', 
        ]);
      }
    }

    rows.add([]); 

    rows.add(['RINGKASAN PEMBAYARAN']);
    rows.add(['Total Pemasukan Tunai', totalTunai]);
    rows.add(['Total Pemasukan QRIS', totalQRIS]);
    rows.add(['GRAND TOTAL PENDAPATAN (A)', grandTotalPemasukan]);
    rows.add(['TOTAL MODAL BARANG (B)', grandTotalModal]);
    rows.add(['LABA BERSIH (A - B)', grandTotalPemasukan - grandTotalModal]);
    rows.add([]); 
    rows.add(['TOTAL FISIK UANG DI KOTAK (Modal Awal + Tunai)', (session['modal_awal'] + totalTunai)]);

    String csvData = const ListToCsvConverter().convert(rows);

    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final fileName = "Laporan_${session['stand_name']}_${session['closed_at'].toString().split('T')[0]}.csv";
    
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click(); 
      
    html.Url.revokeObjectUrl(url); 
  }

  // --- FUNGSI LOGIKA KERANJANG ---
  double get _cartTotal => _cart.fold(0, (sum, item) => sum + (item['price'] * item['qty']));

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingItemIndex = _cart.indexWhere((item) => item['id'] == product['id']);
      int currentCartQty = existingItemIndex >= 0 ? _cart[existingItemIndex]['qty'] : 0;
      
      if (currentCartQty >= product['stock']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stok tidak mencukupi!"), backgroundColor: Colors.red));
        return;
      }

      if (existingItemIndex >= 0) {
        _cart[existingItemIndex]['qty']++;
      } else {
        _cart.add({...product, 'qty': 1});
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      final existingItemIndex = _cart.indexWhere((item) => item['id'] == productId);
      if (existingItemIndex >= 0) {
        if (_cart[existingItemIndex]['qty'] > 1) {
          _cart[existingItemIndex]['qty']--;
        } else {
          _cart.removeAt(existingItemIndex);
          if (_cart.isEmpty) _isCartExpanded = false;
        }
      }
    });
  }

  // --- UI DIALOGS ---

  void _showOpenSessionDialog() {
    final operatorController = TextEditingController();
    final standNameController = TextEditingController(); 
    final modalController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Buka Stand Inforsa", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: standNameController, decoration: const InputDecoration(labelText: "Keterangan/Nama Stand", prefixIcon: Icon(Icons.storefront))),
            const SizedBox(height: 10),
            TextField(controller: operatorController, decoration: const InputDecoration(labelText: "Nama Penjaga Shift", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 10),
            TextField(
              controller: modalController, 
              keyboardType: const TextInputType.numberWithOptions(decimal: true), 
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
              decoration: const InputDecoration(labelText: "Modal Awal (Tunai)", prefixIcon: Icon(Icons.payments)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (operatorController.text.isEmpty || standNameController.text.isEmpty || modalController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua kolom wajib diisi!"), backgroundColor: Colors.red));
                 return;
              }
              double parsedModal = double.tryParse(modalController.text) ?? 0;
              _openSession(operatorController.text, parsedModal, standNameController.text);
            },
            child: const Text("Mulai Jualan"),
          )
        ],
      ),
    );
  }

  void _showCloseSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tutup Sesi Penjualan?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Pastikan semua transaksi sudah selesai. Status stand akan dikunci."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: _closeSession, 
            child: const Text("Tutup Stand"),
          )
        ],
      ),
    );
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Riwayat Stand Inforsa", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  // TITIK BEDAH 3: Tambahkan kata "modal" di query ini
                  future: _supabase.from('sessions').select('''
                    *,
                    transactions (
                      total_amount,
                      payment_method,
                      proof_url,
                      transaction_items (product_name, qty, price, modal, total_price)
                    )
                  ''').eq('status', 'closed').order('closed_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada riwayat sesi."));

                    final sessions = snapshot.data!;

                    return ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final transactions = session['transactions'] as List;
                        
                        double totalRevenue = 0;
                        for (var t in transactions) totalRevenue += t['total_amount'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: const Icon(Icons.history_edu, color: AppColors.primary),
                            title: Text(session['stand_name'] ?? 'Stand Reguler', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${session['closed_at'].toString().split('T')[0]}\nPenjaga: ${session['operator_name']} | Total: Rp $totalRevenue"),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Ringkasan Pembayaran:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    _buildPaymentSummary(transactions),
                                    const Divider(),
                                    const Text("Barang Terjual:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    _buildItemsDetail(transactions),
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Modal Awal (Tunai):", style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text("Rp ${session['modal_awal']}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                                        onPressed: () => _exportToCSV(session),
                                        icon: const Icon(Icons.download),
                                        label: const Text("Unduh Laporan (CSV)", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                        onPressed: () => _deleteSession(session['id']),
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text("Hapus Riwayat Sesi"),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentSummary(List transactions) {
    double tunai = 0;
    double qris = 0;
    for (var t in transactions) {
      if (t['payment_method'].toString().contains('Tunai')) tunai += t['total_amount'];
      if (t['payment_method'].toString().contains('QRIS')) qris += t['total_amount'];
    }
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Tunai:"), Text("Rp $tunai")]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("QRIS:"), Text("Rp $qris")]),
      ],
    );
  }

  Widget _buildItemsDetail(List transactions) {
    Map<String, int> aggregatedItems = {};
    for (var t in transactions) {
      for (var item in t['transaction_items']) {
        String name = item['product_name'];
        int qty = item['qty'];
        aggregatedItems[name] = (aggregatedItems[name] ?? 0) + qty;
      }
    }
    
    if (aggregatedItems.isEmpty) return const Text("- Belum ada penjualan -", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    
    return Column(
      children: aggregatedItems.entries.map((e) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(e.key), Text("${e.value} pcs")],
      )).toList(),
    );
  }

  void _showCheckoutDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Metode Pembayaran", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.qr_code, color: AppColors.primary),
                    label: const Text("QRIS"),
                    onPressed: () {
                      Navigator.pop(context); 
                      _showQrisPaymentDialog(); // Panggil fungsi QRIS yang baru
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.money),
                    label: const Text("Tunai"),
                    onPressed: () {
                      Navigator.pop(context); 
                      _showTunaiPaymentDialog(); 
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FUNGSI BARU: Dialog Pembayaran QRIS + Upload Bukti
  void _showQrisPaymentDialog() {
    Uint8List? selectedImageBytes;
    String? imageExtension;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            // Fungsi pilih gambar dari Kamera/Galeri
            Future<void> pickImage(ImageSource source) async {
              final XFile? image = await _picker.pickImage(source: source);
              if (image != null) {
                final bytes = await image.readAsBytes();
                setStateDialog(() {
                  selectedImageBytes = bytes;
                  imageExtension = image.name.split('.').last;
                });
              }
            }

            return AlertDialog(
              title: const Text("Pembayaran QRIS", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Total Tagihan: Rp $_cartTotal", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 15),
                    
                    // Menampilkan Gambar QRIS
                    // Pastikan gambar qris.jpg ada di folder assets dan terdaftar di pubspec.yaml
                    // Jika belum ada, ini akan menampilkan icon error sementara
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/qris.jpg', 
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.qr_code_2, size: 80, color: Colors.grey), Text("QRIS Belum Tersedia", style: TextStyle(fontSize: 12))]
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const Text("Upload Bukti Transfer:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // Tampilan Gambar Bukti yang dipilih
                    if (selectedImageBytes != null) ...[
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: MemoryImage(selectedImageBytes!), fit: BoxFit.cover)),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Tombol Kamera & Galeri
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text("Kamera", style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.image, size: 18),
                            label: const Text("Galeri", style: TextStyle(fontSize: 12)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[300]),
                  // Tombol mati jika belum ada foto bukti
                  onPressed: selectedImageBytes != null ? () {
                    Navigator.pop(context); 
                    _prosesBayarKeDatabase("QRIS", proofBytes: selectedImageBytes, fileExt: imageExtension);
                  } : null, 
                  child: const Text("Upload & Bayar"),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _showTunaiPaymentDialog() {
    double uangDiterima = 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double kembalian = uangDiterima - _cartTotal;
            bool isUangCukup = kembalian >= 0;

            return AlertDialog(
              title: const Text("Pembayaran Tunai", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Tagihan:", style: TextStyle(fontSize: 16)),
                        Text("Rp $_cartTotal", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                    decoration: InputDecoration(
                      labelText: "Uang Diterima (Rp)",
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) => setStateDialog(() => uangDiterima = double.tryParse(value) ?? 0),
                  ),
                  const SizedBox(height: 16),
                  if (uangDiterima > 0) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isUangCukup ? "Kembalian:" : "Uang Kurang:", style: const TextStyle(fontSize: 16)),
                        Text("Rp ${kembalian.abs()}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isUangCukup ? AppColors.success : Colors.red)),
                      ],
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[300]),
                  onPressed: (uangDiterima > 0 && isUangCukup) ? () {
                    Navigator.pop(context); 
                    _prosesBayarKeDatabase("Tunai (Kembali Rp $kembalian)");
                  } : null, 
                  child: const Text("Uang Diterima"),
                )
              ],
            );
          }
        );
      }
    );
  }

  // --- RENDER UI ---

  @override
  Widget build(BuildContext context) {
    if (!_isSessionOpen) {
      return Scaffold(
        appBar: AppBar(title: const Text("POS - Stand Inforsa"), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text("Stand saat ini sedang ditutup.", style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                icon: const Icon(Icons.play_arrow),
                label: const Text("Buka Stand Baru", style: TextStyle(fontSize: 16)),
                onPressed: _showOpenSessionDialog,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary, width: 2), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                icon: const Icon(Icons.history),
                label: const Text("Lihat Riwayat Stand", style: TextStyle(fontSize: 16)),
                onPressed: _showHistorySheet,
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_standName.isNotEmpty ? _standName : "Transaksi Penjualan"),
            Text("Penjaga: $_operatorName", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
            label: const Text("Tutup Sesi", style: TextStyle(color: Colors.white)),
            onPressed: _showCloseSessionDialog,
          )
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('products').stream(primaryKey: ['id']).eq('category', 'store_stand').order('name'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada barang jualan."));

              final products = snapshot.data!;

              return ListView.builder(
                padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: _isCartExpanded ? 300 : 120), 
                itemCount: products.length,
                itemBuilder: (_, i) {
                  final item = products[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        backgroundImage: item['image_url'] != null ? NetworkImage(item['image_url']) : null,
                        child: item['image_url'] == null ? const Icon(Icons.inventory_2, color: Colors.grey) : null,
                      ),
                      title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Rp ${item['price']} | Stok: ${item['stock']}"),
                      trailing: ElevatedButton(
                        onPressed: item['stock'] > 0 ? () => _addToCart(item) : null,
                        child: Text(item['stock'] > 0 ? "Tambah" : "Habis"),
                      ),
                    ),
                  );
                },
              );
            }
          ),

          if (_cart.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) setState(() => _isCartExpanded = true); 
                  else if (details.primaryVelocity! > 0) setState(() => _isCartExpanded = false); 
                },
                onTap: () => setState(() => _isCartExpanded = !_isCartExpanded),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, -5))]),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(padding: const EdgeInsets.only(top: 10, bottom: 5), child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                        if (_isCartExpanded)
                          Container(
                            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                            child: ListView.builder(
                              shrinkWrap: true, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _cart.length,
                              itemBuilder: (context, index) {
                                final item = _cart[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero, title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Rp ${item['price']}"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _removeFromCart(item['id'])),
                                      Text("${item['qty']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 10),
                                      SizedBox(width: 80, child: Text("Rp ${item['qty'] * item['price']}", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        if (_isCartExpanded) const Divider(thickness: 1, height: 1),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 15, 24, 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${_cart.fold(0, (sum, item) => sum + (item['qty'] as int))} Barang ditambahkan", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text("Rp $_cartTotal", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: () {
                                    setState(() => _isCartExpanded = false);
                                    _showCheckoutDialog();
                                  },
                                  child: const Text("Bayar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}