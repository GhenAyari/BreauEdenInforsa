import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../main.dart'; 
import '../core/colors.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _pengurusList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tarikDataPengurus(); 
  }

  Future<void> _tarikDataPengurus() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // Menggunakan .select() biasa agar tidak bergantung pada setting Realtime Supabase
      final data = await _supabase.from('pengurus').select().order('nama_lengkap', ascending: true);
      if (mounted) {
        setState(() {
          _pengurusList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error tarik pengurus: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

 
  Future<void> _showAddUserDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'Penyewaan';
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Tambah Pengurus Baru", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nama Lengkap", prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 10),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email Login", prefixIcon: Icon(Icons.email))),
                  const SizedBox(height: 10),
                  TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Password (Min. 6 Karakter)", prefixIcon: Icon(Icons.lock))),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: "Akses Divisi", prefixIcon: Icon(Icons.admin_panel_settings)),
                    items: ['Admin', 'Penyewaan', 'PreOrder', 'POS_Barang'].map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedRole = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: isLoading ? null : () async {
                  if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data belum lengkap / Password kurang dari 6!")));
                    return;
                  }

                  setDialogState(() => isLoading = true);

                  try {
               
                    final url = dotenv.env['SUPABASE_URL'] ?? 'https://lukiszwznteofbswbdbo.supabase.co';
                    final serviceKey = dotenv.env['SUPABASE_SERVICE_KEY'] ?? '';
                    
                    if (serviceKey.isEmpty) throw "Kunci SUPABASE_SERVICE_KEY belum dipasang di .env!";

            
                    final adminClient = SupabaseClient(url, serviceKey);

               
                    final userRes = await adminClient.auth.admin.createUser(
                      AdminUserAttributes(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text,
                        emailConfirm: true, 
                      ),
                    );

                    if (userRes.user != null) {
                      // 2. Simpan profilnya ke tabel 'pengurus'
                      await _supabase.from('pengurus').insert({
                        'id': userRes.user!.id,
                        'nama_lengkap': nameCtrl.text.trim(),
                        'divisi_akses': selectedRole,
                        'status': 'Aktif'
                      });
                    }

                    _tarikDataPengurus(); // <--- REFRESH PAKSA SETELAH NAMBAH DATA

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengurus berhasil ditambahkan!"), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    setDialogState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                  }
                },
                child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Simpan"),
              )
            ],
          );
        }
      )
    );
  }

  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    final nameCtrl = TextEditingController(text: user['nama_lengkap']);
    String selectedRole = user['divisi_akses'];
    String selectedStatus = user['status'] ?? 'Aktif';
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Pengurus", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nama Lengkap", prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: "Akses Divisi", prefixIcon: Icon(Icons.admin_panel_settings)),
                    items: ['Admin', 'Penyewaan', 'PreOrder', 'POS_Barang'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                    onChanged: (val) => setDialogState(() => selectedRole = val!),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: "Status Akun", prefixIcon: Icon(Icons.power_settings_new)),
                    items: ['Aktif', 'Dinonaktifkan'].map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                    onChanged: (val) => setDialogState(() => selectedStatus = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: isLoading ? null : () async {
                  if (nameCtrl.text.isEmpty) return;
                  setDialogState(() => isLoading = true);

                  try {
                    await _supabase.from('pengurus').update({
                      'nama_lengkap': nameCtrl.text.trim(),
                      'divisi_akses': selectedRole,
                      'status': selectedStatus,
                    }).eq('id', user['id']);

                    _tarikDataPengurus(); // <--- REFRESH PAKSA SETELAH UPDATE DATA

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data berhasil diupdate!"), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    setDialogState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                  }
                },
                child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Update"),
              )
            ],
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan & Akun"),
        backgroundColor: AppColors.primary, 
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          
          // SAKLAR DARK MODE
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier, 
              builder: (context, currentMode, child) {
                final isDark = currentMode == ThemeMode.dark;
                
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: const Text("Mode Gelap", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Ubah tampilan aplikasi menjadi gelap"),
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode, 
                      color: isDark ? Colors.amber : Colors.orange
                    ),
                    value: isDark,
                    onChanged: (value) async {
                      themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      prefs.setBool('is_dark_mode', value);
                    },
                  ),
                );
              }
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Daftar Pengurus (Admin)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                // Tombol Refresh Kecil Buat Jaga-Jaga
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                  onPressed: _tarikDataPengurus,
                  tooltip: "Refresh Daftar",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
          ),

          // DAFTAR PENGURUS
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _pengurusList.isEmpty
                  ? const Center(child: Text("Belum ada data pengurus."))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _pengurusList.length,
                      itemBuilder: (context, index) {
                        final user = _pengurusList[index];
                        final bool isAktif = user['status'] == 'Aktif';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isAktif ? AppColors.primary : Colors.grey,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(user['nama_lengkap'], style: TextStyle(fontWeight: FontWeight.bold, decoration: isAktif ? null : TextDecoration.lineThrough)),
                            subtitle: Text("Divisi: ${user['divisi_akses']}\nStatus: ${user['status'] ?? 'Aktif'}"),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showEditUserDialog(user),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text("Tambah Pengurus"),
      ),
    );
  }
}