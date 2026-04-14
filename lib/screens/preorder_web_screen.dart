import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../core/colors.dart'; // Sesuaikan path ini jika beda
import 'preorder_admin_screen.dart';

class PreorderWebScreen extends StatefulWidget {
  const PreorderWebScreen({super.key});

  @override
  State<PreorderWebScreen> createState() => _PreorderWebScreenState();
}

class _PreorderWebScreenState extends State<PreorderWebScreen> {
  final _supabase = Supabase.instance.client;

  Future<void> _deletePoForm(String formId, String formTitle) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Form PO?"),
        content: Text("Yakin ingin menghapus form '$formTitle'?\n\nPERINGATAN: Semua pesanan mahasiswa di form ini akan ikut terhapus permanen!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Hapus")
          ),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      await _supabase.from('po_submissions').delete().eq('form_id', formId);
      await _supabase.from('po_settings').delete().eq('id', formId);
      
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Form PO berhasil dihapus!"), backgroundColor: Colors.red));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Pre-Order Aktif"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('po_settings')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada form PO."));

          final allPoList = snapshot.data!;
          final activePoList = allPoList.where((po) => po['is_active'] == true).toList();

          if (activePoList.isEmpty) return const Center(child: Text("Belum ada form PO yang aktif."));

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85, 
            ),
            itemCount: activePoList.length, 
            itemBuilder: (context, index) {
              final po = activePoList[index]; 
              final String bannerUrl = po['banner_url'] ?? '';

              return Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Colors.blue.shade50,
                        child: bannerUrl.isNotEmpty
                            ? Image.network(bannerUrl, fit: BoxFit.cover)
                            : const Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0), // Padding disesuaikan
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(po['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(po['description'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 10),
                          
                          // PERBAIKAN: Dibungkus FittedBox agar kebal Overflow di HP
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.blue, size: 20),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4), // Area sentuh yang aman
                                  onPressed: () {
                                    final link = "https://unrivaled-daffodil-b35f26.netlify.app/?id=${po['id']}";
                                    Clipboard.setData(ClipboardData(text: link));
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Link ${po['title']} disalin!"), backgroundColor: Colors.green));
                                  },
                                ),
                                const SizedBox(width: 8), // Spasi diperkecil
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => PreorderAdminScreen(existingPo: po)));
                                  },
                                ),
                                const SizedBox(width: 8), // Spasi diperkecil
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed: () => _deletePoForm(po['id'].toString(), po['title']),
                                ),
                              ],
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
    );
  }
}