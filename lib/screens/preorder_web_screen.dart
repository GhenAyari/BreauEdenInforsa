import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../core/colors.dart'; 
import 'preorder_admin_screen.dart';
import '../services/log_service.dart';

class PreorderWebScreen extends StatefulWidget {
  const PreorderWebScreen({super.key});

  @override
  State<PreorderWebScreen> createState() => _PreorderWebScreenState();
}

class _PreorderWebScreenState extends State<PreorderWebScreen> {
  final _supabase = Supabase.instance.client;


  List<Map<String, dynamic>> _poList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tarikDataPO(); 
  }

  
  Future<void> _tarikDataPO() async {
    if (mounted) setState(() => _isLoading = true);
    
    try {
    
      final data = await _supabase
          .from('po_settings')
          .select()
          .order('created_at', ascending: false);
          
      if (mounted) {
        setState(() {
          _poList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error tarik Katalog PO: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  
  Future<void> _deletePoForm(String formId, String formTitle) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Form PO?"),
        content: Text("Yakin ingin menghapus form '$formTitle'?\n\nPERINGATAN: Semua pesanan mahasiswa di form ini akan ikut terhapus permanen!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text("Hapus")),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      await _supabase.from('po_submissions').delete().eq('form_id', formId);
      await _supabase.from('po_settings').delete().eq('id', formId);
      
      
      await LogService.catatAktivitas(modul: 'po_settings', aksi: 'HAPUS');

      if (mounted) { 
        Navigator.pop(context); 
        _tarikDataPO(); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Form PO berhasil dihapus!"), backgroundColor: Colors.red)); 
      }
    } catch (e) {
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)); }
    }
  }

  Future<void> _togglePoStatus(String formId, bool currentStatus, String title) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      // Kebalikan dari status saat ini (kalau true jadi false, kalau false jadi true)
      await _supabase.from('po_settings').update({'is_active': !currentStatus}).eq('id', formId);
      
     
      await LogService.catatAktivitas(modul: 'po_settings', aksi: 'UBAH');

      if (mounted) {
        Navigator.pop(context);
        _tarikDataPO(); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(!currentStatus ? "Form '$title' diaktifkan!" : "Form '$title' dijeda!"), 
          backgroundColor: !currentStatus ? Colors.green : Colors.orange
        ));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // Popup Konfirmasi Jeda/Aktifkan Form
  Future<void> _confirmToggleStatus(String formId, bool currentStatus, String title) async {
    String actionText = currentStatus ? "menjeda" : "mengaktifkan";
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentStatus ? "Jeda Form PO?" : "Aktifkan Form PO?", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Yakin ingin $actionText form '$title'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: currentStatus ? Colors.orange : Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(currentStatus ? "Ya, Jeda" : "Ya, Aktifkan")
          ),
        ],
      )
    ) ?? false;

    if (confirm) {
      _togglePoStatus(formId, currentStatus, title);
    }
  }

  // Popup Konfirmasi Edit Form
  Future<void> _confirmEdit(Map<String, dynamic> po) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Form PO?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Yakin ingin masuk ke halaman edit untuk form '${po['title']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya, Edit")
          ),
        ],
      )
    ) ?? false;

    if (confirm && mounted) {
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => PreorderAdminScreen(existingPo: po))
      ).then((_) => _tarikDataPO()); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Katalog Form Web PO"), 
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Tombol Refresh manual di pojok kanan atas
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
            onPressed: _tarikDataPO,
          ),
        ],
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _tarikDataPO,
              child: _poList.isEmpty
                  ? ListView( 
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 300),
                        Center(child: Text("Belum ada form PO.")),
                      ],
                    )
                  : GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(), 
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85, 
                      ),
                      itemCount: _poList.length, 
                      itemBuilder: (context, index) {
                        final po = _poList[index]; 
                        final String bannerUrl = po['banner_url'] ?? '';
                        final bool isActive = po['is_active'] == true; 

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: isActive ? 3 : 1, 
                          color: isActive ? Colors.white : Colors.grey.shade200, 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      color: Colors.blue.shade50,
                                      child: bannerUrl.isNotEmpty
                                          ? Image.network(bannerUrl, fit: BoxFit.cover, color: isActive ? null : Colors.grey, colorBlendMode: isActive ? null : BlendMode.saturation) // Gambar hitam putih kalau dijeda
                                          : const Icon(Icons.image, size: 50, color: Colors.grey),
                                    ),
                            
                                    Positioned(
                                      top: 8, right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(12)),
                                        child: Text(isActive ? "Aktif" : "Dijeda", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0), 
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(po['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isActive ? Colors.black : Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(po['description'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 10),
                                    
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                    
                                          IconButton(
                                            icon: Icon(isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, color: isActive ? Colors.orange : Colors.green, size: 20),
                                            tooltip: isActive ? "Jeda Form" : "Aktifkan Form",
                                            constraints: const BoxConstraints(), padding: const EdgeInsets.all(4),
                                            onPressed: () => _confirmToggleStatus(po['id'].toString(), isActive, po['title']),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.copy, color: Colors.blue, size: 20),
                                            tooltip: "Salin Link",
                                            constraints: const BoxConstraints(), padding: const EdgeInsets.all(4),
                                            onPressed: () {
                                              final link = "https://unrivaled-daffodil-b35f26.netlify.app/?id=${po['id']}";
                                              Clipboard.setData(ClipboardData(text: link));
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Link ${po['title']} disalin!"), backgroundColor: Colors.green));
                                            },
                                          ),
                                          const SizedBox(width: 8), 
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                                            tooltip: "Edit",
                                            constraints: const BoxConstraints(), padding: const EdgeInsets.all(4),
                                            onPressed: () => _confirmEdit(po),
                                          ),
                                          const SizedBox(width: 8), 
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                            tooltip: "Hapus",
                                            constraints: const BoxConstraints(), padding: const EdgeInsets.all(4),
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
                    ),
            ),
    );
  }
}