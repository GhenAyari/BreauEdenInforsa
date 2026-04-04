import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/colors.dart'; // Sesuaikan path ini jika perlu

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  double _totalPendapatan = 0;
  double _totalPengeluaran = 0;
  double _labaBersih = 0;

  @override
  void initState() {
    super.initState();
    _fetchFinancialReport();
  }

  // Fungsi untuk memformat angka jadi Rupiah (titik ribuan)
  String formatRupiah(double amount) {
    return "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  Future<void> _fetchFinancialReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      double tempPendapatan = 0;
      double tempPengeluaran = 0;

      // ===============================================
      // 1. AMBIL DATA POS (Dari Sesi yang sudah Closed)
      // ===============================================
      final sessions = await _supabase.from('sessions').select('''
        transactions (
          total_amount,
          transaction_items (
            qty, modal
          )
        )
      ''').eq('status', 'closed');

      for (var session in sessions) {
        final transactions = session['transactions'] as List;
        for (var trx in transactions) {
          tempPendapatan += (trx['total_amount'] ?? 0); // Tambah ke Pendapatan
          
          final items = trx['transaction_items'] as List;
          for (var item in items) {
            // Hitung Modal (Pengeluaran) = Harga Modal x Jumlah Terjual
            tempPengeluaran += ((item['modal'] ?? 0) * (item['qty'] ?? 0));
          }
        }
      }

      // ===============================================
      // 2. AMBIL DATA PENYEWAAN (Yang Telah Selesai/Dikembalikan)
      // ===============================================
      final rentals = await _supabase.from('rentals').select('total_price').eq('status', 'Dikembalikan');
      for (var rental in rentals) {
        tempPendapatan += (rental['total_price'] ?? 0);
      }

      // ===============================================
      // 3. AMBIL DATA PRE-ORDER (Yang Sudah Diterima)
      // ===============================================
      final preorders = await _supabase.from('preorders').select('total_price').eq('status', 'Sudah Diterima');
      for (var po in preorders) {
        tempPendapatan += (po['total_price'] ?? 0);
      }

      // ===============================================
      // 4. KALKULASI HASIL AKHIR
      // ===============================================
      if (mounted) {
        setState(() {
          _totalPendapatan = tempPendapatan;
          _totalPengeluaran = tempPengeluaran;
          _labaBersih = tempPendapatan - tempPengeluaran;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat laporan: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Keuangan"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFinancialReport, // Tombol refresh data
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchFinancialReport,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("Ringkasan Keseluruhan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 15),
                  
                  // KARTU PENDAPATAN
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.arrow_downward, color: Colors.white)),
                      title: const Text("Total Pendapatan", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Dari POS, Sewa & PO"),
                      trailing: Text(formatRupiah(_totalPendapatan), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // KARTU PENGELUARAN (MODAL)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.arrow_upward, color: Colors.white)),
                      title: const Text("Total Pengeluaran", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Dari Modal Barang Terjual"),
                      trailing: Text(formatRupiah(_totalPengeluaran), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                    ),
                  ),
                  const Divider(height: 30, thickness: 2),
                  
                  // KARTU LABA BERSIH
                  Card(
                    color: AppColors.primary,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Laba Bersih", style: TextStyle(color: Colors.white70, fontSize: 16)),
                              SizedBox(height: 5),
                              Text("Keuntungan Saat Ini", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text(
                            formatRupiah(_labaBersih), 
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}