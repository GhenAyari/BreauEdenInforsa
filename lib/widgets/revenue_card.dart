import 'dart:async'; // IMPORT BARU: Untuk CCTV Realtime
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/colors.dart';

class RevenueCard extends StatefulWidget {
  const RevenueCard({super.key});

  @override
  State<RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<RevenueCard> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  int _posKotor = 0;
  int _posBersih = 0;
  int _sewaTotal = 0;

  // VARIABEL CCTV
  StreamSubscription? _rentalSub;
  StreamSubscription? _posSub;

  @override
  void initState() {
    super.initState();
    _listenToRevenue();
  }

  void _listenToRevenue() {
    // 1. CCTV TABEL PENYEWAAN (rentals)
    _rentalSub = _supabase.from('rentals').stream(primaryKey: ['id']).listen((data) {
      int tempSewa = 0;
      for (var item in data) {
        tempSewa += int.tryParse(item['total_price'].toString()) ?? 0;
      }
      if (mounted) {
        setState(() {
          _sewaTotal = tempSewa;
          _isLoading = false;
        });
      }
    }, onError: (error) => debugPrint("Aman diabaikan - Error Rentals: $error"));

    // 2. CCTV TABEL POS (transactions) - Nama tabel sudah disesuaikan!
    _posSub = _supabase.from('transactions').stream(primaryKey: ['id']).listen((data) {
      int tempPosKotor = 0;
      int tempPosBersih = 0;

      for (var item in data) {
        int price = int.tryParse(item['total_price'].toString()) ?? 0;
        int modal = int.tryParse(item['total_modal'].toString()) ?? 0;

        tempPosKotor += price;
        tempPosBersih += (price - modal);
      }
      
      if (mounted) {
        setState(() {
          _posKotor = tempPosKotor;
          _posBersih = tempPosBersih;
          _isLoading = false;
        });
      }
    }, onError: (error) => debugPrint("Aman diabaikan - Error POS: $error"));
  }

  @override
  void dispose() {
    // Wajib dimatikan agar memori HP tidak bocor saat tutup aplikasi
    _rentalSub?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  // Fungsi untuk memformat angka jadi ada titiknya (Rp 1.000.000)
  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  // ==========================================
  // FITUR BOTTOM SHEET RINCIAN
  // ==========================================
  void _showDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Rincian Pendapatan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              _buildDetailRow("POS (Pendapatan Kotor)", _posKotor),
              _buildDetailRow("POS (Keuntungan Bersih)", _posBersih, isNet: true),
              const SizedBox(height: 10),
              
              _buildDetailRow("Penyewaan (Total)", _sewaTotal),
              
              const Divider(height: 30, thickness: 1.5),
              
              _buildDetailRow("Total Pendapatan Kotor", _posKotor + _sewaTotal, isBold: true),
              _buildDetailRow("Total Keuntungan Bersih", _posBersih + _sewaTotal, isBold: true, isNet: true),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  // Widget bantuan untuk baris rincian biar kodingan rapi
  Widget _buildDetailRow(String label, int amount, {bool isBold = false, bool isNet = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isNet ? Colors.green[700] : Colors.black87)),
          Text(
            "Rp ${_formatCurrency(amount)}", 
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: isNet ? Colors.green[700] : Colors.black87)
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Total yang dipajang di depan adalah Total Pendapatan Kotor (Omzet)
    int totalPendapatanKotor = _posKotor + _sewaTotal;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _isLoading ? null : _showDetails, 
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TOTAL PENDAPATAN", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              
              _isLoading
                  ? const SizedBox(height: 38, width: 38, child: CircularProgressIndicator())
                  : Text(
                      "Rp ${_formatCurrency(totalPendapatanKotor)}",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
              
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text("Dari POS & Sewa", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 12)),
                  const Spacer(),
                  const Text("Klik lihat rincian 👉", style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}