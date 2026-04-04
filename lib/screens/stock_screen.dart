import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../core/colors.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  SupabaseClient get _supabase => Supabase.instance.client;
  
  // Inisialisasi Image Picker
  final ImagePicker _picker = ImagePicker();

  // FUNGSI: Helper untuk membuat List Barang berdasarkan Kategori
  Widget _buildProductList(String category) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('products')
          .stream(primaryKey: ['id'])
          .eq('category', category) 
          .order('created_at', ascending: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Belum ada data barang di kategori ini.'));
        }

        final products = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (_, index) {
            final product = products[index];
            
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: product['image_url'] != null
                      ? NetworkImage(product['image_url'])
                      : null,
                  child: product['image_url'] == null 
                      ? const Icon(Icons.inventory_2, color: Colors.grey)
                      : null,
                ),
                title: Text(
                  product['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // TAMPILAN DIPERBARUI: Menampilkan Modal juga
                subtitle: Text("Stok: ${product['stock']} | Harga: Rp ${product['price']} | Modal: Rp ${product['modal'] ?? 0}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () => _showFormDialog(product: product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteProduct(product),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  // Fungsi untuk menampilkan Pop-up Form
  Future<void> _showFormDialog({Map<String, dynamic>? product}) async {
    final isEditing = product != null; 
    
    final nameController = TextEditingController(text: isEditing ? product['name'] : '');
    final priceController = TextEditingController(text: isEditing ? product['price'].toString() : '');
    // CONTROLLER BARU: Untuk Modal
    final modalController = TextEditingController(text: isEditing ? (product['modal']?.toString() ?? '0') : '');
    final stockController = TextEditingController(text: isEditing ? product['stock'].toString() : '');
    
    // Variabel untuk menyimpan kategori (Default: store_stand)
    String selectedCategory = isEditing ? (product['category'] ?? 'store_stand') : 'store_stand';
    
    // Variabel untuk menyimpan gambar
    Uint8List? selectedImageBytes;
    String? currentImageUrl = isEditing ? product['image_url'] : null;
    String? imageExtension;

    await showDialog(
      context: context,
      builder: (context) {
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
              title: Text(isEditing ? 'Edit Barang' : 'Tambah Barang Baru', 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Area Foto
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Galeri'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.gallery);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Kamera'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.camera);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(selectedImageBytes!, fit: BoxFit.cover),
                              )
                            : currentImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(currentImageUrl!, fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Tambah Foto', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dropdown Kategori (Store/Stand vs Eden)
                   DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Lokasi Penyimpanan', prefixIcon: Icon(Icons.location_on_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'store_stand', child: Text('Store & Stand')),
                        DropdownMenuItem(value: 'eden', child: Text('Eden (Gudang)')),
                        DropdownMenuItem(value: 'penyewaan', child: Text('Penyewaan')), // <--- TAMBAH INI
                      ],
                      onChanged: (val) {
                        setStateDialog(() { selectedCategory = val!; });
                      },
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Barang', prefixIcon: Icon(Icons.inventory_2_outlined)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga Jual (Rp)', prefixIcon: Icon(Icons.sell_outlined)),
                    ),
                    const SizedBox(height: 10),
                    
                    // INPUT BARU: Kolom Modal
                    TextField(
                      controller: modalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Modal Satuan (Rp)', prefixIcon: Icon(Icons.savings_outlined)),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Jumlah Stok', prefixIcon: Icon(Icons.numbers)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // Validasi bertambah: Modal wajib diisi
                    if (nameController.text.isEmpty || priceController.text.isEmpty || stockController.text.isEmpty || modalController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama, Harga, Modal, dan Stok wajib diisi!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    showDialog(
                      context: context, 
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    final name = nameController.text;
                    final price = num.tryParse(priceController.text) ?? 0;
                    final modal = num.tryParse(modalController.text) ?? 0; // TANGKAP INPUT MODAL
                    final stock = int.tryParse(stockController.text) ?? 0;
                    
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

                      // Susun data yang akan dikirim (termasuk Modal)
                      final productData = {
                        'name': name,
                        'price': price,
                        'modal': modal, // SIMPAN MODAL KE DATABASE
                        'stock': stock,
                        'category': selectedCategory, 
                        'image_url': finalImageUrl,
                      };

                      if (isEditing) {
                        await _supabase.from('products').update(productData).eq('id', product['id']);
                      } else {
                        await _supabase.from('products').insert(productData);
                      }
                      
                      if (mounted) {
                        Navigator.pop(context); 
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Barang berhasil diubah!' : 'Barang baru ditambahkan!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
                        );
                      }
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
        title: const Text('Hapus Barang'),
        content: const Text('Yakin ingin menghapus barang ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red))
          ),
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang dan foto berhasil dihapus'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
         print("Error hapus: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Manajemen Stok"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Store & Stand"),
              Tab(text: "Eden"),
              Tab(text: "Penyewaan"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProductList('store_stand'), 
            _buildProductList('eden'),    
            _buildProductList('penyewaan'),    
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