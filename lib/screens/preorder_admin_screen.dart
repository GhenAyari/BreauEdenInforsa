import 'dart:convert';
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../core/colors.dart'; 
import 'package:flutter/services.dart'; 
// ========================================================
// IMPORT AGEN RAHASIA LOG SERVICE
// ========================================================
import '../services/log_service.dart';

class PreorderAdminScreen extends StatefulWidget {
  final Map<String, dynamic>? existingPo; 
  const PreorderAdminScreen({super.key, this.existingPo});

  @override
  State<PreorderAdminScreen> createState() => _PreorderAdminScreenState();
}

class _PreorderAdminScreenState extends State<PreorderAdminScreen> {
  final _supabase = Supabase.instance.client;
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  String? _bannerUrl; 
  Uint8List? _imageBytes; 
  String? _imageExtension;
  bool _isUploadingImage = false;

  List<Map<String, dynamic>> _questions = [];

  String? _titleError;
  String? _questionsError;

  bool get isEditing => widget.existingPo != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.existingPo!['title'] ?? '';
      _descController.text = widget.existingPo!['description'] ?? '';
      _bannerUrl = widget.existingPo!['banner_url']; 

      var rawQ = widget.existingPo!['questions'];
      if (rawQ is String) {
        try { _questions = List<Map<String, dynamic>>.from(jsonDecode(rawQ)); } catch(e) {}
      } else if (rawQ is List) {
        _questions = List<Map<String, dynamic>>.from(rawQ);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      final bytes = await image.readAsBytes(); 
      setState(() {
        _imageBytes = bytes;
        _imageExtension = image.name.split('.').last; 
        _bannerUrl = null; 
      });
    }
  }

  Future<String?> _uploadBannerImage() async {
    if (_imageBytes == null) return _bannerUrl; 

    setState(() => _isUploadingImage = true);
    try {
      final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.$_imageExtension';
      await _supabase.storage.from('po_banners').uploadBinary(fileName, _imageBytes!, fileOptions: FileOptions(contentType: 'image/$_imageExtension'));
      return _supabase.storage.from('po_banners').getPublicUrl(fileName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal upload banner: $e"), backgroundColor: Colors.red));
      return null;
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _showQuestionDialog({int? editIndex}) {
    final bool isEditMode = editIndex != null;
    final existingQ = isEditMode ? _questions[editIndex] : null;

    final labelController = TextEditingController(text: isEditMode ? existingQ!['label'] : '');
    String typePilihan = isEditMode ? existingQ!['type'] : 'text'; 
    bool isRequired = isEditMode ? existingQ!['required'] : true;
    
    Uint8List? tempStmtImageBytes;
    String? tempStmtImageExt;
    String? tempStmtImageUrl = isEditMode ? existingQ!['imageUrl'] : null;

    List<String> tempOptions = [];
    if (isEditMode && existingQ!['options'] != null) {
      tempOptions = List<String>.from(existingQ!['options']);
    }
    final optionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditMode ? "Edit Item" : "Tambah Item Baru"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: typePilihan,
                      decoration: const InputDecoration(labelText: "Tipe Item"),
                      items: const [
                        DropdownMenuItem(value: 'text', child: Text('Teks Singkat')),
                        DropdownMenuItem(value: 'number', child: Text('Angka (Jumlah/No HP)')),
                        DropdownMenuItem(value: 'file', child: Text('Upload File (Gambar/PDF)')),
                        DropdownMenuItem(value: 'choice', child: Text('Pilihan (Dropdown)')), 
                        DropdownMenuItem(value: 'statement', child: Text('Pernyataan (Info/Gambar)')), 
                      ],
                      onChanged: (val) => setStateDialog(() => typePilihan = val!),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: labelController, 
                      maxLines: typePilihan == 'statement' ? 3 : 1, 
                      decoration: InputDecoration(
                        labelText: typePilihan == 'statement' ? "Teks Pernyataan" : "Pertanyaan (Contoh: Ukuran Baju)",
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder()
                      )
                    ),
                    
                    if (typePilihan != 'statement') ...[
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Wajib Diisi?"), 
                        value: isRequired, 
                        onChanged: (val) => setStateDialog(() => isRequired = val)
                      )
                    ],

                    if (typePilihan == 'choice') ...[
                      const SizedBox(height: 15),
                      const Text("Opsi Pilihan:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                      
                      ...tempOptions.asMap().entries.map((entry) {
                        int idx = entry.key;
                        String opt = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.grey.shade300)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ========================================================
                              // PERBAIKAN: Tanda minus (-) dihapus dari sini!
                              // ========================================================
                              Text(opt, style: const TextStyle(fontWeight: FontWeight.bold)),
                              
                              InkWell(
                                onTap: () => setStateDialog(() => tempOptions.removeAt(idx)),
                                child: const Icon(Icons.close, color: Colors.red, size: 18),
                              )
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: optionController,
                              decoration: const InputDecoration(hintText: "Ketik opsi (Misal: XL)", isDense: true, border: OutlineInputBorder()),
                            )
                          ),
                          const SizedBox(width: 5),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () {
                              if (optionController.text.isNotEmpty) {
                                setStateDialog(() {
                                  tempOptions.add(optionController.text.trim());
                                  optionController.clear();
                                });
                              }
                            }, 
                            child: const Text("Tambah")
                          )
                        ],
                      )
                    ],

                    if (typePilihan == 'statement') ...[
                      const SizedBox(height: 15),
                      const Text("Gambar Info (Opsional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setStateDialog(() {
                              tempStmtImageBytes = bytes;
                              tempStmtImageExt = image.name.split('.').last;
                              tempStmtImageUrl = null; 
                            });
                          }
                        },
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[400]!)),
                          child: tempStmtImageBytes != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(tempStmtImageBytes!, fit: BoxFit.cover))
                              : tempStmtImageUrl != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(tempStmtImageUrl!, fit: BoxFit.cover))
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, color: Colors.grey, size: 30),
                                        Text("Pilih Gambar", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () {
                    if (labelController.text.isEmpty && tempStmtImageBytes == null && tempStmtImageUrl == null) return;
                    
                    if (typePilihan == 'choice' && tempOptions.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tambahkan minimal 1 opsi pilihan!")));
                       return;
                    }

                    setState(() {
                      final newItem = {
                        "id": isEditMode ? existingQ!['id'] : "q_${DateTime.now().millisecondsSinceEpoch}", 
                        "label": labelController.text.trim(),
                        "type": typePilihan,
                        "required": typePilihan == 'statement' ? false : isRequired, 
                      };
                      
                      if (typePilihan == 'choice') {
                        newItem['options'] = tempOptions;
                      }

                      if (typePilihan == 'statement') {
                        if (tempStmtImageBytes != null) {
                          newItem['imageBytes'] = tempStmtImageBytes;
                          newItem['imageExt'] = tempStmtImageExt;
                        }
                        if (tempStmtImageUrl != null) newItem['imageUrl'] = tempStmtImageUrl;
                      }

                      if (isEditMode) {
                        _questions[editIndex] = newItem;
                      } else {
                        _questions.add(newItem);
                      }

                      _questionsError = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(isEditMode ? "Simpan" : "Tambahkan"),
                )
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _savePOSetting() async {
    bool isValid = true;
    setState(() {
      if (_titleController.text.trim().isEmpty) {
        _titleError = "Judul PO tidak boleh kosong!";
        isValid = false;
      } else {
        _titleError = null;
      }

      if (_questions.isEmpty) {
        _questionsError = "Minimal harus membuat 1 Item Form!";
        isValid = false;
      } else {
        _questionsError = null;
      }
    });

    if (!isValid) return; 

    // ========================================================
    // FITUR BARU: Popup Konfirmasi Saat Menyimpan Editan
    // ========================================================
    if (isEditing) {
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Simpan Perubahan?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Yakin ingin menyimpan perubahan pada form PO ini? Pastikan semua data sudah benar."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Ya, Simpan")
            ),
          ],
        )
      ) ?? false;

      if (!confirm) return; // Batal simpan kalau pencet cancel
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      String? finalBannerUrl = await _uploadBannerImage();

      List<Map<String, dynamic>> questionsToSave = [];
      for (int i = 0; i < _questions.length; i++) {
        Map<String, dynamic> q = Map.from(_questions[i]); 
        
        if (q['type'] == 'statement' && q['imageBytes'] != null) {
          final ext = q['imageExt'];
          final fileName = 'stmt_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
          await _supabase.storage.from('po_banners').uploadBinary(fileName, q['imageBytes'], fileOptions: FileOptions(contentType: 'image/$ext'));
          final publicUrl = _supabase.storage.from('po_banners').getPublicUrl(fileName);
          q['imageUrl'] = publicUrl; 
          _questions[i]['imageUrl'] = publicUrl; 
        }
        
        q.remove('imageBytes');
        q.remove('imageExt');
        questionsToSave.add(q);
      }

      final poData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'banner_url': finalBannerUrl ?? '', 
        'is_active': true,
        'questions': jsonEncode(questionsToSave), 
      };

      if (isEditing) {
        await _supabase.from('po_settings').update(poData).eq('id', widget.existingPo!['id']);
        
        // ========================================================
        // CATAT LOG PERUBAHAN PO SETTING
        // ========================================================
        await LogService.catatAktivitas(modul: 'po_settings', aksi: 'UBAH');

        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perubahan Form Berhasil Disimpan!"), backgroundColor: Colors.green));
          Navigator.pop(context, true); 
        }
      } else {
        final response = await _supabase.from('po_settings').insert(poData).select().single();
        
        // ========================================================
        // CATAT LOG PENAMBAHAN PO SETTING
        // ========================================================
        await LogService.catatAktivitas(modul: 'po_settings', aksi: 'TAMBAH');

        final String newId = response['id'];
        final String shareLink = "https://unrivaled-daffodil-b35f26.netlify.app/?id=$newId";

        if (mounted) {
          Navigator.pop(context); 
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("Form Berhasil Terbit! 🚀"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Berikan link ini kepada mahasiswa untuk mengisi PO:"),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade400)),
                    child: SelectableText(shareLink, style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              actions: [
                ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), onPressed: () {Clipboard.setData(ClipboardData(text: shareLink)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link disalin!"), backgroundColor: Colors.green));}, icon: const Icon(Icons.copy, size: 18), label: const Text("Salin Link")),
                TextButton(onPressed: () {Navigator.pop(context); Navigator.pop(context, true);}, child: const Text("Selesai", style: TextStyle(color: Colors.grey))),
              ],
            ),
          );
        }
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
      appBar: AppBar(title: Text(isEditing ? "Edit Form Pre-Order" : "Buat Form Pre-Order Baru"), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Informasi Dasar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController, 
              decoration: InputDecoration(
                labelText: "Judul PO (Misal: Jaket Himpunan)", 
                border: const OutlineInputBorder(),
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: "Deskripsi / Keterangan PO", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            
            const Text("Banner Form (Opsional)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[400]!)),
                child: _imageBytes != null ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity)) : _bannerUrl != null && _bannerUrl!.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_bannerUrl!, fit: BoxFit.cover, width: double.infinity)) : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey), SizedBox(height: 8), Text("Ketuk untuk upload gambar dari galeri", style: TextStyle(color: Colors.grey))]),
              ),
            ),
            
            const Divider(height: 40, thickness: 2),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Daftar Item Form", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(onPressed: () => _showQuestionDialog(), icon: const Icon(Icons.add), label: const Text("Tambah"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white))
              ],
            ),
            if (_questionsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_questionsError!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 10),
            
            if (_questions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada item. Klik Tambah untuk membuat.")))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  
                  IconData typeIcon = Icons.text_fields;
                  if (q['type'] == 'number') typeIcon = Icons.numbers;
                  if (q['type'] == 'file') typeIcon = Icons.upload_file; 
                  if (q['type'] == 'statement') typeIcon = Icons.info_outline; 
                  if (q['type'] == 'choice') typeIcon = Icons.arrow_drop_down_circle; 

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: q['type'] == 'statement' ? Colors.blueGrey : Colors.blue, child: Icon(typeIcon, color: Colors.white, size: 18)),
                      title: Text(q['label'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(q['type'] == 'statement' ? "Tipe: Info" : q['type'] == 'choice' ? "Tipe: Pilihan (${(q['options'] as List?)?.length ?? 0} opsi)" : "Tipe: ${q['type']} | Wajib: ${q['required'] ? 'Ya' : 'Tidak'}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showQuestionDialog(editIndex: index)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() { _questions.removeAt(index); })),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isUploadingImage ? null : _savePOSetting,
                child: _isUploadingImage ? const CircularProgressIndicator(color: Colors.white) : Text(isEditing ? "SIMPAN PERUBAHAN FORM" : "SIMPAN & TERBITKAN FORM PO", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}