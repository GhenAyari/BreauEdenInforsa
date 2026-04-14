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
    // Menarik data dari CCTV kita, diurutkan dari yang paling baru
    _logStream = _supabase
        .from('log_aktivitas')
        .stream(primaryKey: ['id'])
        .order('waktu', ascending: false);
  }

  // Fungsi untuk memformat tanggal & jam biar enak dibaca
  String _formatDateTime(String isoString) {
    DateTime dt = DateTime.parse(isoString).toLocal();
    return "${dt.day}/${dt.month}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  // Menentukan Ikon dan Warna berdasarkan Jenis Aksi
  Icon _getAksiIcon(String aksi) {
    if (aksi == 'TAMBAH') return const Icon(Icons.add_circle, color: Colors.green);
    if (aksi == 'UBAH') return const Icon(Icons.edit, color: Colors.orange);
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
                    backgroundColor: Colors.white,
                    child: _getAksiIcon(log['aksi'] ?? ''),
                  ),
                  title: Text(
                    "${log['nama_user']} (${log['divisi_user']})", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Melakukan ${log['aksi']} pada modul '${log['modul']}'", style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(_formatDateTime(log['waktu']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
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