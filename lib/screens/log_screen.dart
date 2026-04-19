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
  late Stream<List<Map<String, dynamic>>> _logStream;

  @override
  void initState() {
    super.initState();
  
    _logStream = _supabase
        .from('log_aktivitas')
        .stream(primaryKey: ['id'])
        .order('waktu', ascending: false);
  }

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return "-";
    DateTime dt = DateTime.parse(isoString).toLocal();
    return "${dt.day}/${dt.month}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
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
      ),
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _logStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Belum ada riwayat aktivitas yang tercatat.", style: TextStyle(color: Colors.grey)),
            );
          }

          final logs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              
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
                      
                      // =====================================
                      // TAMPILAN BARU: LOG NAMA PERANGKAT
                      // =====================================
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
          );
        },
      ),
    );
  }
}