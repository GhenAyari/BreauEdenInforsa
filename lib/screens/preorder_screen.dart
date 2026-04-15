import 'dart:io';
import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/colors.dart';
import 'preorder_admin_screen.dart';
import 'preorder_web_screen.dart';

class PreOrderScreen extends StatefulWidget {
  const PreOrderScreen({super.key});

  @override
  State<PreOrderScreen> createState() => _PreOrderScreenState();
}

class _PreOrderScreenState extends State<PreOrderScreen> {
  final _supabase = Supabase.instance.client;

  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription? _poSub;
  List<Map<String, dynamic>> _allPoList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tarikDataPO(); 
  }


  void _tarikDataPO() {
    if (mounted) setState(() => _isLoading = true);
    
    _poSub?.cancel(); 
    _poSub = _supabase
        .from('po_settings')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
          if (mounted) {
            setState(() {
              _allPoList = data;
              _isLoading = false;
            });
          }
        }, onError: (e) {
          if (mounted) setState(() => _isLoading = false);
        });
  }

  @override
  void dispose() {
    _poSub?.cancel(); 
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Manajemen Pre-Order"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
           
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Data",
              onPressed: () {
                _tarikDataPO();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menyegarkan data..."), duration: Duration(seconds: 1)));
              },
            ),
            IconButton(
              icon: const Icon(Icons.preview),
              tooltip: "Lihat Web Pembeli",
              onPressed: () {
                FocusScope.of(context).unfocus();
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PreorderWebScreen(),
                  ),
                ).then((_) => _tarikDataPO());
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Aktif (Belum Diterima)"),
              Tab(text: "Riwayat Selesai"),
            ],
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Cari nama Form PO...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey.shade100, // Dukungan Dark Mode
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _allPoList.isEmpty
                    ? const Center(child: Text("Belum ada Form PO."))
                    : TabBarView(
                        children: [
                          Builder(
                            builder: (context) {
                              final poList = _allPoList.where((po) {
                                final isMatchStatus = po['is_active'] == true;
                                final isMatchSearch = po['title']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_searchQuery);
                                return isMatchStatus && isMatchSearch;
                              }).toList();

                              if (poList.isEmpty)
                                return Center(
                                  child: Text(
                                    _searchQuery.isEmpty
                                        ? "Belum ada Form PO yang aktif."
                                        : "Pencarian tidak ditemukan.",
                                  ),
                                );

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                itemCount: poList.length,
                                itemBuilder: (context, index) {
                                  final po = poList[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.blue,
                                        child: Icon(
                                          Icons.folder,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        po['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        "Lihat pesanan yang belum diambil",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PoDetailScreen(
                                                  poId: po['id'].toString(),
                                                  poTitle: po['title'],
                                                  statusFilter:
                                                      'Belum Diterima',
                                                ),
                                          ),
                                        ).then((_) => _tarikDataPO()); // Refresh saat balik
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          Builder(
                            builder: (context) {
                              final poList = _allPoList
                                  .where(
                                    (po) => po['title']
                                        .toString()
                                        .toLowerCase()
                                        .contains(_searchQuery),
                                  )
                                  .toList();

                              if (poList.isEmpty)
                                return const Center(
                                  child: Text("Pencarian tidak ditemukan."),
                                );

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                itemCount: poList.length,
                                itemBuilder: (context, index) {
                                  final po = poList[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Icon(
                                          Icons.folder_special,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        po['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        "Lihat riwayat pesanan selesai",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PoDetailScreen(
                                              poId: po['id'].toString(),
                                              poTitle:
                                                  "${po['title']} (Selesai)",
                                              statusFilter: 'Sudah Diterima',
                                            ),
                                          ),
                                        ).then((_) => _tarikDataPO()); // Refresh saat balik
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PreorderAdminScreen(),
              ),
            ).then((_) => _tarikDataPO()); // Refresh saat balik dari bikin form
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("Buat Form PO Web"),
        ),
      ),
    );
  }
}


class PoDetailScreen extends StatefulWidget {
  final String poId;
  final String poTitle;
  final String statusFilter;

  const PoDetailScreen({
    super.key,
    required this.poId,
    required this.poTitle,
    required this.statusFilter,
  });

  @override
  State<PoDetailScreen> createState() => _PoDetailScreenState();
}

class _PoDetailScreenState extends State<PoDetailScreen> {
  final _supabase = Supabase.instance.client;

  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription? _subsSub;
  List<Map<String, dynamic>> _allSubsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tarikDataRefresh(); 
  }

  void _tarikDataRefresh() {
    if (mounted) setState(() => _isLoading = true);
    
    _subsSub?.cancel(); 
    _subsSub = _supabase
        .from('po_submissions')
        .stream(primaryKey: ['id'])
        .eq('form_id', widget.poId) 
        .order('submitted_at', ascending: false)
        .listen(
          (data) {
            if (mounted) {
              setState(() {
                _allSubsList = data;
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            debugPrint("Stream error: $error");
            if (mounted) setState(() => _isLoading = false);
          },
        );
  }

  @override
  void dispose() {
    _subsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _getCustomerName(Map<String, dynamic> answers) {
    for (var key in answers.keys) {
      if (key.toLowerCase().contains("nama")) {
        return answers[key].toString();
      }
    }
    return answers.isNotEmpty ? answers.values.first.toString() : "Tanpa Nama";
  }

 
  String _formatTanggalWaktu(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      String y = dt.year.toString();
      String m = dt.month.toString().padLeft(2, '0');
      String d = dt.day.toString().padLeft(2, '0');
      String h = dt.hour.toString().padLeft(2, '0');
      String min = dt.minute.toString().padLeft(2, '0');
      return "$y-$m-$d $h:$min";
    } catch (e) {
      return isoString.split('T')[0]; // Jaga-jaga kalau error, balik ke tanggal aja
    }
  }

  Future<void> _exportToCSV() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await _supabase
          .from('po_submissions')
          .select()
          .eq('form_id', widget.poId)
          .eq('status', widget.statusFilter)
          .order('submitted_at', ascending: false);
      final submissions = List<Map<String, dynamic>>.from(response);

      if (submissions.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tidak ada data untuk diekspor!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      Set<String> answerKeys = {};
      for (var sub in submissions) {
        final Map<String, dynamic> answers = sub['answers'] ?? {};
        answerKeys.addAll(answers.keys);
      }

      List<List<dynamic>> csvData = [];
      List<String> headers = [
        "Nama Pelanggan",
        "Waktu Submit", 
        "Status Pesanan",
        ...answerKeys,
      ];
      csvData.add(headers);

      for (var sub in submissions) {
        final Map<String, dynamic> answers = sub['answers'] ?? {};
        String customerName = _getCustomerName(answers);
        String waktuLengkap = _formatTanggalWaktu(sub['submitted_at'].toString()); // Pakai jam menit

        List<dynamic> row = [
          customerName,
          waktuLengkap,
          sub['status'],
        ];
        for (var key in answerKeys) {
          row.add(answers[key]?.toString() ?? "-");
        }
        csvData.add(row);
      }

      String csv = const ListToCsvConverter().convert(csvData);
      final dir = await getTemporaryDirectory();
      final safeTitle = widget.poTitle
          .replaceAll(" ", "_")
          .replaceAll("/", "_");
      final path = '${dir.path}/Data_PO_$safeTitle.csv';

      final file = File(path);
      await file.writeAsString(csv);

      if (mounted) {
        Navigator.pop(context);
        await Share.shareXFiles(
          [XFile(path)],
          text:
              'Berikut adalah lampiran file Excel/CSV untuk data: ${widget.poTitle}',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal Ekspor: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsReceived(
    BuildContext context,
    dynamic submissionId,
    String customerName,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await _supabase
          .from('po_submissions')
          .update({'status': 'Sudah Diterima'})
          .eq('id', submissionId);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSubmission(
    BuildContext context,
    dynamic submissionId,
  ) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Pesanan?"),
            content: const Text("Pesanan mahasiswa ini akan dihapus permanen."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Hapus"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await _supabase.from('po_submissions').delete().eq('id', submissionId);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Gagal membuka link: $urlString");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.poTitle),
        backgroundColor: widget.statusFilter == 'Sudah Diterima'
            ? Colors.green
            : AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
        
          IconButton(
            icon: const Icon(Icons.refresh), 
            tooltip: "Refresh Data", 
            onPressed: () {
              _tarikDataRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Menyegarkan data..."), duration: Duration(seconds: 1))
              );
            }
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Ekspor ke CSV/Excel",
            onPressed: _exportToCSV,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Cari nama mahasiswa...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                            });
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey.shade100, // Dukungan Dark Mode
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allSubsList.isEmpty
                  ? const Center(
                      child: Text(
                        "Belum ada pesanan untuk PO ini.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final filteredSubmissions = _allSubsList.where((sub) {
                         
                          final customerName = _getCustomerName(
                            sub['answers'] ?? {},
                          );
                          final isMatchStatus =
                              sub['status'] == widget.statusFilter;
                          final isMatchSearch = customerName
                              .toLowerCase()
                              .contains(_searchQuery);

                          return isMatchStatus && isMatchSearch;
                        }).toList();

                        if (filteredSubmissions.isEmpty) {
                          return Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? "Belum ada pesanan di kategori ini."
                                  : "Pemesan tidak ditemukan.",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filteredSubmissions.length,
                          itemBuilder: (context, subIndex) {
                            final sub = filteredSubmissions[subIndex];
                            final Map<String, dynamic> answers =
                                sub['answers'] ?? {};
                            String customerName = _getCustomerName(answers);
                            String waktuLengkap = _formatTanggalWaktu(sub['submitted_at'].toString()); // Jam dan Menit

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                              child: ExpansionTile(
                                onExpansionChanged: (expanded) {
                                  if (expanded)
                                    FocusScope.of(context).unfocus();
                                },
                                leading: CircleAvatar(
                                  backgroundColor:
                                      widget.statusFilter == 'Sudah Diterima'
                                      ? Colors.green
                                      : Colors.orange,
                                  child: Icon(
                                    widget.statusFilter == 'Sudah Diterima'
                                        ? Icons.check
                                        : Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "Tgl Submit: $waktuLengkap", 
                                  style: const TextStyle(fontSize: 12),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Detail Jawaban Pembeli:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const Divider(),

                                        ...answers.entries.map((entry) {
                                          String valStr = entry.value
                                              .toString();
                                          bool isLink = valStr.startsWith(
                                            "http",
                                          );
                                          bool isImage =
                                              isLink &&
                                              (valStr.toLowerCase().contains(
                                                    ".jpg",
                                                  ) ||
                                                  valStr.toLowerCase().contains(
                                                    ".png",
                                                  ) ||
                                                  valStr.toLowerCase().contains(
                                                    ".jpeg",
                                                  ));

                                          Widget contentWidget;
                                          if (isImage) {
                                            contentWidget = GestureDetector(
                                              onTap: () => _openUrl(valStr),
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                height: 120,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    valStr,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => const Center(
                                                          child: Text(
                                                            "Gagal muat foto",
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else if (isLink) {
                                            contentWidget = GestureDetector(
                                              onTap: () => _openUrl(valStr),
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.blue.shade200,
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.download,
                                                      color: Colors.blue,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      "Buka Dokumen/File",
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          } else {
                                            contentWidget = Text(
                                              valStr,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12.0,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    "${entry.key} : ",
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: contentWidget,
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),

                                        const SizedBox(height: 15),

                                        if (widget.statusFilter ==
                                            'Belum Diterima')
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed: () =>
                                                      _deleteSubmission(
                                                        context,
                                                        sub['id'],
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                  ),
                                                  label: const Text("Hapus"),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                flex: 2,
                                                child: ElevatedButton.icon(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed: () =>
                                                      _markAsReceived(
                                                        context,
                                                        sub['id'],
                                                        customerName,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.check,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    "Tandai Diambil",
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.done_all,
                                                  color: Colors.green,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  "PESANAN SUDAH SELESAI",
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}