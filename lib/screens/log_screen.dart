import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/colors.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _supabase = Supabase.instance.client;
  
  // PERBAIKAN 1: Ganti Stream jadi List biasa
  List<Map<String, dynamic>> _logList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tarikDataLog(); 
  }

 
  Future<void> _tarikDataLog() async {
    if (mounted) setState(() => _isLoading = true);
    
    try {
      final data = await _supabase
          .from('log_aktivitas')
          .select()
          .order('waktu', ascending: false);
          
      if (mounted) {
        setState(() {
          _logList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error tarik log: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      return "${dt.day}/${dt.month}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString; 
    }
  }

  Icon _getAksiIcon(String aksi) {
    if (aksi == 'TAMBAH') return const Icon(Icons.add_circle, color: Colors.green);
    if (aksi == 'UBAH' || aksi == 'EDIT') return const Icon(Icons.edit, color: Colors.orange);
    if (aksi == 'HAPUS') return const Icon(Icons.delete, color: Colors.red);
    return const Icon(Icons.info, color: Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Aktivitas"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
        
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
            onPressed: _tarikDataLog,
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
   
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _tarikDataLog, // Fungsi saat layar ditarik ke bawah
              child: _logList.isEmpty
                  ? ListView(
                      // Pake ListView kosong biar tetep bisa ditarik layarnya
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 300),
                        Center(
                          child: Text("Belum ada riwayat aktivitas yang tercatat.", style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(), 
                      padding: const EdgeInsets.all(12),
                      itemCount: _logList.length,
                      itemBuilder: (context, index) {
                        final log = _logList[index];
                        
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade100,
                              child: _getAksiIcon(log['aksi'] ?? ''),
                            ),
                            title: Text(
                              "${log['nama_user'] ?? 'Tidak Diketahui'} (${log['divisi_user'] ?? '-'})", 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text("Melakukan ${log['aksi']} pada modul '${log['modul']}'", style: const TextStyle(color: Colors.black87)),
                                const SizedBox(height: 6),
                                
                                Row(
                                  children: [
                                    const Icon(Icons.devices, size: 14, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        log['nama_perangkat'] ?? 'Perangkat Lama (Supabase)', 
                                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(_formatDateTime(log['waktu'] ?? ''), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}