import 'dart:async'; 
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:flutter/foundation.dart';
import '../core/colors.dart';

class CurrencyFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numericOnly.isEmpty) {
      return oldValue;
    }

    if (numericOnly.length > 8) {
      return oldValue; 
    }

    int value = int.parse(numericOnly);
    final newText = value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  SupabaseClient get _supabase => Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  StreamSubscription? _productSub;
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoading = true;
  
  String _userRole = "";
  bool _isRoleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRoleAndData();
  }

  Future<void> _loadRoleAndData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userRole = prefs.getString("user_role") ?? "Admin";
        _isRoleLoaded = true;
      });
    }

    _tarikDataBarang(); 
  }

  Future<void> _tarikDataBarang() async {
    if (mounted) setState(() => _isLoading = true);
    
    try {
      final data = await _supabase.from('products').select().order('created_at', ascending: true);
      if (mounted) {
        setState(() {
          _allProducts = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error tarik barang: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _productSub?.cancel(); 
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi andalan buat ngasih titik ribuan ke angka murni dari database
  String _formatInitialCurrency(dynamic value) {
    if (value == null) return '';
    int val = value is int ? value : (num.tryParse(value.toString())?.toInt() ?? 0);
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  Widget _buildProductList(String category) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final categoryProducts = _allProducts.where((p) => p['category'] == category).toList();

    if (categoryProducts.isEmpty) {
      return const Center(child: Text('Belum ada data barang di kategori ini.'));
    }

    final filteredProducts = categoryProducts.where((product) {
      final productName = product['name'].toString().toLowerCase();
      return productName.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredProducts.isEmpty) {
      return const Center(child: Text('Tidak ada barang yang cocok dengan pencarian.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredProducts.length,
      itemBuilder: (_, index) {
        final product = filteredProducts[index];
        
        // ========================================================
        // PERBAIKAN: Angka harga & modal dibungkus format ribuan
        // ========================================================
        Widget subtitleWidget;
        if (product['category'] == 'eden') {
          subtitleWidget = Text("Stok: ${product['stock']}");
        } else if (product['category'] == 'penyewaan') {
          subtitleWidget = Text("Stok: ${product['stock']} | Tarif: Rp ${_formatInitialCurrency(product['price'])}/hari");
        } else {
          subtitleWidget = Text("Stok: ${product['stock']} | Harga: Rp ${_formatInitialCurrency(product['price'])} | Modal: Rp ${_formatInitialCurrency(product['modal'] ?? 0)}");
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[200],
              backgroundImage: product['image_url'] != null ? NetworkImage(product['image_url']) : null,
              child: product['image_url'] == null ? const Icon(Icons.inventory_2, color: Colors.grey) : null,
            ),
            title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: subtitleWidget),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: AppColors.primary), onPressed: () => _showFormDialog(product: product)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteProduct(product)),
              ],
            ),
          ),
        );
      }
    );
  }

  Future<void> _showFormDialog({Map<String, dynamic>? product}) async {
    final isEditing = product != null; 
    
    final nameController = TextEditingController(text: isEditing ? product['name'] : '');
    final priceController = TextEditingController(text: isEditing ? _formatInitialCurrency(product['price']) : '');
    final modalController = TextEditingController(text: isEditing ? _formatInitialCurrency(product['modal']) : '');
    final stockController = TextEditingController(text: isEditing ? product['stock'].toString() : '');
    
    String selectedCategory = isEditing 
        ? (product['category'] ?? 'store_stand') 
        : (_userRole == 'Penyewaan' ? 'penyewaan' : 'store_stand');
    
    Uint8List? selectedImageBytes;
    String? currentImageUrl = isEditing ? product['image_url'] : null;
    String? imageExtension;

    await showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        String? errorName;
        String? errorPrice;
        String? errorModal;
        String? errorStock;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            Future<void> pickImage(ImageSource source) async {
              final XFile? image = await _picker.pickImage(source: source);
              if (image != null) {
                final bytes = await image.readAsBytes(); 
                setStateDialog(() {
                  selectedImageBytes = bytes;
                  currentImageUrl = null; 
                  imageExtension = image.name.split('.').last; 
                });
              }
            }

            return AlertDialog(
              title: Text(isEditing ? 'Edit Barang' : 'Tambah Barang Baru', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeri'), onTap: () { Navigator.pop(context); pickImage(ImageSource.gallery); }),
                                ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Kamera'), onTap: () { Navigator.pop(context); pickImage(ImageSource.camera); }),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 120, width: 120,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[400]!)),
                        child: selectedImageBytes != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(selectedImageBytes!, fit: BoxFit.cover))
                            : currentImageUrl != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(currentImageUrl!, fit: BoxFit.cover))
                                : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), SizedBox(height: 8), Text('Tambah Foto', style: TextStyle(fontSize: 12, color: Colors.grey))]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Lokasi Penyimpanan', prefixIcon: Icon(Icons.location_on_outlined)),
                      items: _userRole == 'Penyewaan' 
                          ? const [DropdownMenuItem(value: 'penyewaan', child: Text('Penyewaan'))]
                          : const [
                              DropdownMenuItem(value: 'store_stand', child: Text('Store & Stand')),
                              DropdownMenuItem(value: 'eden', child: Text('Eden (Gudang)')),
                              DropdownMenuItem(value: 'penyewaan', child: Text('Penyewaan')), 
                            ],
                      onChanged: (val) { setStateDialog(() { selectedCategory = val!; errorPrice = null; errorModal = null; }); },
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: nameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-_.,()&/+%]'))
                      ],
                      decoration: InputDecoration(labelText: 'Nama Barang', prefixIcon: const Icon(Icons.inventory_2_outlined), errorText: errorName),
                      onChanged: (_) { if (errorName != null) setStateDialog(() => errorName = null); },
                    ),
                    const SizedBox(height: 10),
                    
                    if (selectedCategory != 'eden') ...[
                      TextField(
                        controller: priceController,
                        keyboardType: kIsWeb ? TextInputType.text : TextInputType.number,
                        inputFormatters: [CurrencyFormat()],
                        decoration: InputDecoration(
                          labelText: selectedCategory == 'penyewaan' ? 'Tarif Sewa per Hari (Rp)' : 'Harga Jual (Rp)', 
                          prefixIcon: Icon(selectedCategory == 'penyewaan' ? Icons.event_note : Icons.sell_outlined), 
                          errorText: errorPrice
                        ),
                        onChanged: (_) { if (errorPrice != null) setStateDialog(() => errorPrice = null); },
                      ),
                      const SizedBox(height: 10),
                      
                      if (selectedCategory != 'penyewaan') ...[
                        TextField(
                          controller: modalController,
                          keyboardType: kIsWeb ? TextInputType.text : TextInputType.number,
                          inputFormatters: [CurrencyFormat()],
                          decoration: InputDecoration(labelText: 'Modal Satuan (Rp)', prefixIcon: const Icon(Icons.savings_outlined), errorText: errorModal),
                          onChanged: (_) { if (errorModal != null) setStateDialog(() => errorModal = null); },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],

                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                      decoration: InputDecoration(labelText: 'Jumlah Stok', prefixIcon: const Icon(Icons.numbers), errorText: errorStock),
                      onChanged: (_) { if (errorStock != null) setStateDialog(() => errorStock = null); },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: AppColors.textLight))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    bool isValid = true;
                    setStateDialog(() {
                      if (nameController.text.trim().isEmpty) { errorName = "Nama tidak boleh kosong!"; isValid = false; }
                      if (selectedCategory != 'eden') {
                        if (priceController.text.trim().isEmpty) { errorPrice = "Harga/Tarif wajib diisi!"; isValid = false; }
                        if (selectedCategory != 'penyewaan') {
                          if (modalController.text.trim().isEmpty) { errorModal = "Modal wajib diisi!"; isValid = false; }
                        }
                      }
                      if (stockController.text.trim().isEmpty) { errorStock = "Stok wajib diisi!"; isValid = false; }
                    });
                    if (!isValid) return;

                    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

                    final name = nameController.text.trim();
                    final price = selectedCategory == 'eden' ? 0 : (num.tryParse(priceController.text.replaceAll('.', '')) ?? 0);
                    final modal = (selectedCategory == 'eden' || selectedCategory == 'penyewaan') ? 0 : (num.tryParse(modalController.text.replaceAll('.', '')) ?? 0); 
                    final stock = int.tryParse(stockController.text.replaceAll('.', '')) ?? 0;
                    String? finalImageUrl = isEditing ? product['image_url'] : null;

                    try {
                      if (selectedImageBytes != null) {
                        if (isEditing && product['image_url'] != null) {
                          final oldFileName = Uri.parse(product['image_url']).pathSegments.last;
                          await _supabase.storage.from('product_image').remove([oldFileName]);
                        }
                        final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.${imageExtension ?? 'jpg'}';
                        await _supabase.storage.from('product_image').uploadBinary(fileName, selectedImageBytes!);
                        finalImageUrl = _supabase.storage.from('product_image').getPublicUrl(fileName);
                      }

                      final productData = {
                        'name': name, 'price': price, 'modal': modal, 'stock': stock,
                        'category': selectedCategory, 'image_url': finalImageUrl,
                      };

                      if (isEditing) {
                        await _supabase.from('products').update(productData).eq('id', product['id']);
                      } else {
                        await _supabase.from('products').insert(productData);
                      }
                      
                      _tarikDataBarang();

                      if (mounted) {
                        Navigator.pop(context); Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Barang berhasil diubah!' : 'Barang baru ditambahkan!'), backgroundColor: AppColors.success));
                      }
                    } catch (e) {
                      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red)); }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Barang'), content: const Text('Yakin ingin menghapus barang ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (confirm == true) {
      try {
        if (product['image_url'] != null) {
          final fileName = Uri.parse(product['image_url']).pathSegments.last;
          await _supabase.storage.from('product_image').remove([fileName]);
        }
        await _supabase.from('products').delete().eq('id', product['id']);
        
        _tarikDataBarang();

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barang berhasil dihapus'), backgroundColor: Colors.red));
      } catch (e) { print("Error hapus: $e"); }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRoleLoaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final int tabCount = _userRole == 'Penyewaan' ? 1 : 3;

    return DefaultTabController(
      length: tabCount, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Manajemen Stok"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Daftar Stok",
              onPressed: () {
                _tarikDataBarang();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menyegarkan stok..."), duration: Duration(seconds: 1)));
              },
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: _userRole == 'Penyewaan'
                ? const [Tab(text: "Penyewaan")]
                : const [
                    Tab(text: "Store & Stand"),
                    Tab(text: "Eden"),
                    Tab(text: "Penyewaan"),
                  ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) { setState(() { _searchQuery = value; }); },
                decoration: InputDecoration(
                  hintText: "Cari nama barang...",
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _searchController.clear(); setState(() { _searchQuery = ''; }); })
                      : null,
                  filled: true, fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey[100], 
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            
            Expanded(
              child: TabBarView(
                children: _userRole == 'Penyewaan'
                    ? [ _buildProductList('penyewaan') ]
                    : [
                        _buildProductList('store_stand'), 
                        _buildProductList('eden'),    
                        _buildProductList('penyewaan'),   
                      ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showFormDialog(), 
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}