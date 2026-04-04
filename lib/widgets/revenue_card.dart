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
  double _totalPendapatan = 0;

  @override
  void initState() {
    super.initState();
    _fetchTotalRevenue();
  }

  // Fungsi format Rupiah
  String formatRupiah(double amount) {
    return "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  // Fungsi Kalkulasi Total Pendapatan
  Future<void> _fetchTotalRevenue() async {
    try {
      double tempPendapatan = 0;

      // 1. Pemasukan POS
      final sessions = await _supabase.from('sessions').select('transactions(total_amount)').eq('status', 'closed');
      for (var session in sessions) {
        final transactions = session['transactions'] as List;
        for (var trx in transactions) {
          tempPendapatan += (trx['total_amount'] ?? 0);
        }
      }

      // 2. Pemasukan Penyewaan
      final rentals = await _supabase.from('rentals').select('total_price').eq('status', 'Dikembalikan');
      for (var rental in rentals) {
        tempPendapatan += (rental['total_price'] ?? 0);
      }

      // 3. Pemasukan Pre-Order
      final preorders = await _supabase.from('preorders').select('total_price').eq('status', 'Sudah Diterima');
      for (var po in preorders) {
        tempPendapatan += (po['total_price'] ?? 0);
      }

      // Update UI
      if (mounted) {
        setState(() {
          _totalPendapatan = tempPendapatan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint("Error fetch revenue: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "TOTAL PENDAPATAN",
              style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 12),
            
            // Animasi Loading saat menghitung data
            _isLoading 
              ? const SizedBox(
                  height: 33, width: 33, 
                  child: CircularProgressIndicator(color: AppColors.primary)
                )
              : Text(
                  formatRupiah(_totalPendapatan),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary
                  )
                ),
                
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.account_balance_wallet, color: AppColors.success, size: 18),
                SizedBox(width: 6),
                Text(
                  "Dari POS, Sewa & PO",
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}