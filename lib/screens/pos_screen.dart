import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/colors.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _supabase = Supabase.instance.client;

  // --- STATE SESI & KERANJANG ---
  bool _isSessionOpen = false;
  String? _currentSessionId;
  String _operatorName = "";
  double _modalAwal = 0;

  bool _isCartExpanded = false;
  List<Map<String, dynamic>> _cart = [];

  // Data Dummy Riwayat (Kita biarkan dulu sampai transaksi utama lancar)
  final List<Map<String, dynamic>> _pastSessions = [
    {
      'date': '02 April 2026', 'operator': 'Ghendi & Tim', 'modal': 100000, 'revenue': 847000, 'best_seller': 'Pop Mie',
      'sold_items': [{'name': 'Pop Mie', 'qty': 12, 'total': 72000}]
    }
  ];

  @override
  void initState() {
    super.initState();
    _checkActiveSession(); // Cek apakah ada stand yang belum ditutup
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
          _modalAwal = data[0]['modal_awal'].toDouble();
        });
      }
    } catch (e) {
      print("Error cek sesi: $e");
    }
  }

  Future<void> _openSession(String operator, double modal) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await _supabase.from('sessions').insert({
        'operator_name': operator,
        'modal_awal': modal,
        'status': 'open'
      }).select('id').single();

      if (mounted) {
        setState(() {
          _isSessionOpen = true;
          _currentSessionId = response['id'];
          _operatorName = operator;
          _modalAwal = modal;
          _cart.clear();
          _isCartExpanded = false;
        });
        Navigator.pop(context); // Tutup loading
        Navigator.pop(context); // Tutup dialog form
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
        Navigator.pop(context); // Tutup loading
        Navigator.pop(context); // Tutup dialog konfirmasi
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stand berhasil ditutup!")));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal tutup stand: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _prosesBayarKeDatabase(String metodePembayaran) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      // 1. Simpan Transaksi Utama (Catat Total & Metode)
      final trxResponse = await _supabase.from('transactions').insert({
        'session_id': _currentSessionId,
        'payment_method': metodePembayaran,
        'total_amount': _cartTotal,
      }).select('id').single();

      final transactionId = trxResponse['id'];

      // 2. Simpan Detail Transaksi & Kurangi Stok Barang
      for (var item in _cart) {
        // Catat detail barang
        await _supabase.from('transaction_items').insert({
          'transaction_id': transactionId,
          'product_id': item['id'],
          'product_name': item['name'],
          'qty': item['qty'],
          'price': item['price'],
          'total_price': item['qty'] * item['price'],
        });

        // Kurangi stok di database master (products)
        final newStock = item['stock'] - item['qty'];
        await _supabase.from('products').update({'stock': newStock}).eq('id', item['id']);
      }

      if (mounted) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pembayaran $metodePembayaran Berhasil!"), backgroundColor: AppColors.success));
        setState(() {
          _cart.clear();
          _isCartExpanded = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memproses pembayaran: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- FUNGSI LOGIKA KERANJANG ---

  double get _cartTotal => _cart.fold(0, (sum, item) => sum + (item['price'] * item['qty']));

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingItemIndex = _cart.indexWhere((item) => item['id'] == product['id']);
      // Validasi cek stok sebelum tambah
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
    final modalController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Buka Stand Inforsa", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: operatorController, decoration: const InputDecoration(labelText: "Nama Penjaga Shift", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 10),
            TextField(controller: modalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Modal Awal (Tunai)", prefixIcon: Icon(Icons.payments))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (operatorController.text.isNotEmpty && modalController.text.isNotEmpty) {
                 _openSession(operatorController.text, double.tryParse(modalController.text) ?? 0);
              }
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
            onPressed: _closeSession, // Panggil fungsi database
            child: const Text("Tutup Stand"),
          )
        ],
      ),
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
                      _prosesBayarKeDatabase("QRIS"); 
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
                    keyboardType: TextInputType.number,
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
                    _prosesBayarKeDatabase("Tunai"); // Simpan ke database dengan metode Tunai
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

  // Dummy fungsi riwayat
  // FITUR: Menampilkan Riwayat Stand Dinamis dari Supabase
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
                  // Mengambil sesi yang sudah ditutup
                  future: _supabase.from('sessions').select('''
                    *,
                    transactions (
                      total_amount,
                      payment_method,
                      transaction_items (product_name, qty, total_price)
                    )
                  ''').eq('status', 'closed').order('closed_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("Belum ada riwayat sesi."));
                    }

                    final sessions = snapshot.data!;

                    return ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final transactions = session['transactions'] as List;
                        
                        // Hitung Total Pendapatan Sesi Ini
                        double totalRevenue = 0;
                        for (var t in transactions) {
                          totalRevenue += t['total_amount'];
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: const Icon(Icons.history_edu, color: AppColors.primary),
                            title: Text(session['closed_at'].toString().split('T')[0]), // Tanggal tutup
                            subtitle: Text("Penjaga: ${session['operator_name']} | Total: Rp $totalRevenue"),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Ringkasan Pembayaran:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    // Ringkasan Tunai vs QRIS
                                    _buildPaymentSummary(transactions),
                                    const Divider(),
                                    const Text("Barang Terjual:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    _buildItemsDetail(transactions),
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

  // Widget Helper untuk menghitung Ringkasan Pembayaran per Sesi
  Widget _buildPaymentSummary(List transactions) {
    double tunai = 0;
    double qris = 0;
    for (var t in transactions) {
      if (t['payment_method'] == 'Tunai') tunai += t['total_amount'];
      if (t['payment_method'] == 'QRIS') qris += t['total_amount'];
    }
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Tunai:"), Text("Rp $tunai")]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("QRIS:"), Text("Rp $qris")]),
      ],
    );
  }

  // Widget Helper untuk merangkum semua barang yang terjual dalam satu sesi
  Widget _buildItemsDetail(List transactions) {
    Map<String, int> aggregatedItems = {};
    for (var t in transactions) {
      for (var item in t['transaction_items']) {
        String name = item['product_name'];
        int qty = item['qty'];
        aggregatedItems[name] = (aggregatedItems[name] ?? 0) + qty;
      }
    }
    return Column(
      children: aggregatedItems.entries.map((e) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(e.key), Text("${e.value} pcs")],
      )).toList(),
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
            const Text("Transaksi Penjualan"),
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
          // MENGAMBIL DATA PRODUK ASLI DARI SUPABASE
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
                        // Matikan tombol jika stok 0
                        onPressed: item['stock'] > 0 ? () => _addToCart(item) : null,
                        child: Text(item['stock'] > 0 ? "Tambah" : "Habis"),
                      ),
                    ),
                  );
                },
              );
            }
          ),

          // Laci Keranjang (Sama seperti sebelumnya)
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