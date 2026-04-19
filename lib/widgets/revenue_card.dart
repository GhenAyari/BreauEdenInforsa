import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class RevenueCard extends StatefulWidget {
  const RevenueCard({super.key});

  @override
  State<RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<RevenueCard> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  bool _isObscured = false;

  int _posKotor = 0;
  int _posBersih = 0;
  int _sewaTotal = 0;

  StreamSubscription? _rentalSub;
  StreamSubscription? _posSub;

  @override
  void initState() {
    super.initState();
    _loadObscureState(); 
    _kalkulasiSemua();
    _listenToRevenue();
  }


  Future<void> _loadObscureState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        // Cek ingatan, kalau belum pernah dipencet, default-nya false (kelihatan)
        _isObscured = prefs.getBool('is_revenue_hidden') ?? false;
      });
    }
  }

  Future<void> _toggleObscure() async {
    bool newState = !_isObscured;
    setState(() {
      _isObscured = newState;
    });
    
    // Simpan ke memori HP biar nggak lupa pas pindah halaman
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_revenue_hidden', newState);
  }

  void _listenToRevenue() {
    _rentalSub = _supabase.from('rentals').stream(primaryKey: ['id']).listen((_) {
      _kalkulasiSemua();
    });

    _posSub = _supabase.from('sessions').stream(primaryKey: ['id']).listen((_) {
      _kalkulasiSemua();
    });
  }

  Future<void> _kalkulasiSemua() async {
    try {
      final rentalData = await _supabase.from('rentals').select('total_price');
      int tempSewa = 0;
      for (var item in rentalData) {
        tempSewa += (num.tryParse(item['total_price'].toString()) ?? 0).toInt();
      }

      final sessions = await _supabase.from('sessions').select('''
        transactions (
          total_amount,
          transaction_items (qty, modal)
        )
      ''').eq('status', 'closed');

      int tempPosKotor = 0;
      int tempPosBersih = 0;

      for (var session in sessions) {
        final transactions = session['transactions'] as List;
        for (var trx in transactions) {
          int amount = (num.tryParse(trx['total_amount'].toString()) ?? 0).toInt();
          tempPosKotor += amount;

          int totalModalTrx = 0;
          final items = trx['transaction_items'] as List;
          for (var item in items) {
            int modal = (num.tryParse(item['modal'].toString()) ?? 0).toInt();
            int qty = (num.tryParse(item['qty'].toString()) ?? 0).toInt();
            totalModalTrx += (modal * qty);
          }
          
          tempPosBersih += (amount - totalModalTrx);
        }
      }

      if (mounted) {
        setState(() {
          _sewaTotal = tempSewa;
          _posKotor = tempPosKotor;
          _posBersih = tempPosBersih;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error kalkulasi revenue: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _rentalSub?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _showDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Rincian Pendapatan", 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 20),

              // ========================================================
              // PERBAIKAN: Penambahan Label Inforsa Stand & Store di Rincian
              // ========================================================
              _buildDetailRow("POS (Inforsa Stand - Kotor)", _posKotor),
              _buildDetailRow("POS (Inforsa Stand - Bersih)", _posBersih, isNet: true),
              const SizedBox(height: 10),

              _buildDetailRow("Penyewaan (Inforsa Store)", _sewaTotal),

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

  Widget _buildDetailRow(String label, int amount, {bool isBold = false, bool isNet = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
              color: isNet ? Colors.green[700] : Colors.black87
            )
          ),
          Text(
            _isObscured ? "Rp •••••••" : "Rp ${_formatCurrency(amount)}",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600, 
              color: isNet ? Colors.green[700] : Colors.black87
            )
          ),
        ],
      ),
    );
  }

  // ========================================================
  // KARTU UTAMA: GRAND TOTAL (Bisa diklik & ada tombol mata)
  // ========================================================
  Widget _buildGrandTotalCard(int totalPendapatanKotor) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "GRAND TOTAL PENDAPATAN", 
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)
                  ),
                  GestureDetector(
                    onTap: _toggleObscure, 
                    child: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _isLoading
                  ? const SizedBox(height: 38, width: 38, child: CircularProgressIndicator())
                  : Text(
                      _isObscured ? "Rp ••••••••" : "Rp ${_formatCurrency(totalPendapatanKotor)}",
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).primaryColor
                      ),
                    ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    "Dari Inforsa Store & Stand", 
                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 12)
                  ),
                  const Spacer(),
                  const Text(
                    "Klik lihat rincian 👉", 
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // KARTU KECIL: INFORSA STORE / INFORSA STAND (Tidak bisa diklik)
  // ========================================================
  Widget _buildSubRevenueCard(String title, int amount, IconData icon, Color iconColor) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title, 
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    _isObscured ? "Rp •••••" : "Rp ${_formatCurrency(amount)}",
                    style: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.black87
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalPendapatanKotor = _posKotor + _sewaTotal;

    return Column(
      children: [
        // 1. KARTU GRAND TOTAL (Paling Atas)
        _buildGrandTotalCard(totalPendapatanKotor),
        
        const SizedBox(height: 12),
        
        // 2. KARTU INFORSA STORE & STAND (Berjejer di bawah)
        Row(
          children: [
            Expanded(
              child: _buildSubRevenueCard(
                "Inforsa Store (Sewa)", 
                _sewaTotal, 
                Icons.shopping_bag, 
                Colors.blue
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSubRevenueCard(
                "Inforsa Stand (POS)", 
                _posKotor, 
                Icons.storefront, 
                Colors.orange
              ),
            ),
          ],
        ),
      ],
    );
  }
}