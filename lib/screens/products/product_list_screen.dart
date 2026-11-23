import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/product.dart';
import '../../providers/store_provider.dart';
import '../../widgets/product_image_widget.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final products = provider.allProducts;
    final categories = provider.categories;

    return Scaffold(
      backgroundColor: AppTheme.backgroundSand,
      appBar: AppBar(
        title: const Text('Kelola Menu Produk'),
        backgroundColor: AppTheme.primaryNavy,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.category_outlined, size: 20),
            label: const Text('Kelola Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _showManageCategoriesDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accentOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('TAMBAH MENU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showProductDialog(context),
      ),
      body: products.isEmpty
          ? const Center(child: Text('Belum ada menu produk.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (ctx, idx) {
                final product = products[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderBlack, width: 2),
                    boxShadow: AppTheme.brutalistShadow(offset: 2),
                  ),
                  child: Row(
                    children: [
                      ProductImageWidget(
                        product: product,
                        size: 52,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  _formatRupiah(product.price),
                                  style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold),
                                ),
                                if (product.categoryId != null && categories.any((c) => c.id == product.categoryId)) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundSand,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.borderBlack, width: 1),
                                    ),
                                    child: Text(
                                      categories.firstWhere((c) => c.id == product.categoryId).name,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryNavy),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (product.addOns.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${product.addOns.length} add-on tersedia',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.primaryNavy, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Availability Switch
                      Column(
                        children: [
                          Switch(
                            value: product.isAvailable,
                            activeColor: AppTheme.successGreen,
                            onChanged: (val) => provider.toggleProductAvailability(product),
                          ),
                          Text(
                            product.isAvailable ? 'Tersedia' : 'Habis',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: product.isAvailable ? AppTheme.successGreen : AppTheme.dangerRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showProductDialog(context, product: product);
                          } else if (val == 'delete') {
                            provider.deleteProduct(product.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit Menu')),
                          PopupMenuItem(value: 'delete', child: Text('Hapus Menu', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProductFormDialog(product: product),
    );
  }

  void _showManageCategoriesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _ManageCategoriesDialog(),
    );
  }

  static String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}

class _ProductFormDialog extends StatefulWidget {
  final Product? product;

  const _ProductFormDialog({this.product});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _addonNameCtrl;
  late final TextEditingController _addonPriceCtrl;
  List<ProductAddon> _addons = [];
  int? _selectedCategoryId;
  String? _imageUrl;
  bool _isLoadingImage = false;
  bool _showUrlInput = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _priceCtrl = TextEditingController(text: widget.product != null ? widget.product!.price.toString() : '');
    _imageUrl = widget.product?.imageUrl;
    _urlCtrl = TextEditingController(text: (_imageUrl != null && _imageUrl!.startsWith('http')) ? _imageUrl : '');
    _selectedCategoryId = widget.product?.categoryId;
    _addons = widget.product?.addOns.map((a) => a.copyWith()).toList() ?? [];
    _addonNameCtrl = TextEditingController();
    _addonPriceCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _urlCtrl.dispose();
    _addonNameCtrl.dispose();
    _addonPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoadingImage = true);
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 82,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _imageUrl = base64String;
          _urlCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  Widget _buildImagePreview() {
    if (_isLoadingImage) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderBlack, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Memproses foto...'),
          ],
        ),
      );
    }

    if (_imageUrl != null && _imageUrl!.trim().isNotEmpty) {
      final img = _imageUrl!.trim();
      Widget imageContent;
      if (img.startsWith('http://') || img.startsWith('https://')) {
        imageContent = Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _errorPlaceholder());
      } else if (img.startsWith('data:image')) {
        try {
          final bytes = base64Decode(img.split(',').last);
          imageContent = Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _errorPlaceholder());
        } catch (_) {
          imageContent = _errorPlaceholder();
        }
      } else {
        imageContent = _errorPlaceholder();
      }

      return Stack(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderBlack, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageContent,
          ),
          Positioned(
            top: 6,
            right: 6,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black.withOpacity(0.7),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _imageUrl = null;
                    _urlCtrl.clear();
                  });
                },
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid, width: 1.5),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 40, color: AppTheme.textMuted),
          SizedBox(height: 6),
          Text(
            'Belum ada foto menu',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text('Foto tidak dapat dimuat', style: TextStyle(color: Colors.red, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final categories = provider.categories;

    return AlertDialog(
      title: Row(
        children: [
          Icon(widget.product == null ? Icons.add_circle : Icons.edit, color: AppTheme.primaryNavy),
          const SizedBox(width: 8),
          Text(widget.product == null ? 'Tambah Menu Baru' : 'Edit Menu'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Photo Preview & Upload Buttons
              const Text(
                'FOTO MENU',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              _buildImagePreview(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppTheme.primaryNavy),
                      ),
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('Galeri / File', style: TextStyle(fontSize: 12)),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppTheme.primaryNavy),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Kamera', style: TextStyle(fontSize: 12)),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() => _showUrlInput = !_showUrlInput);
                  },
                  child: Text(
                    _showUrlInput ? 'Sembunyikan Link URL' : 'Atau gunakan link URL foto',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              if (_showUrlInput) ...[
                TextField(
                  controller: _urlCtrl,
                  decoration: InputDecoration(
                    labelText: 'Link URL Foto (http/https)',
                    hintText: 'https://example.com/foto.jpg',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        if (_urlCtrl.text.trim().isNotEmpty) {
                          setState(() {
                            _imageUrl = _urlCtrl.text.trim();
                          });
                        }
                      },
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      setState(() {
                        _imageUrl = val.trim();
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
              const Divider(height: 24),

              // 2. Kategori Menu
              if (categories.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  value: (_selectedCategoryId != null && categories.any((c) => c.id == _selectedCategoryId))
                      ? _selectedCategoryId
                      : (categories.any((c) => c.id == widget.product?.categoryId) ? widget.product?.categoryId : categories.first.id),
                  decoration: const InputDecoration(labelText: 'Kategori Menu'),
                  items: categories.map((c) {
                    return DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCategoryId = val);
                  },
                ),
                const SizedBox(height: 12),
              ],

              // 3. Nama Menu
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Menu *',
                  hintText: 'Contoh: Kopi Susu Gula Aren',
                ),
              ),
              const SizedBox(height: 12),

              // 4. Harga
              TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Jual (Rp) *',
                  hintText: 'Contoh: 18000',
                  prefixText: 'Rp ',
                ),
              ),
              const Divider(height: 24),

              // 5. Add-on & Varian
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ADD-ON & VARIAN MENU',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                  ),
                  Text(
                    '${_addons.length} opsi',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_addons.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Belum ada add-on untuk menu ini.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _addons.map((a) {
                    return Chip(
                      backgroundColor: const Color(0xFFEFF6FF),
                      label: Text(
                        '${a.name} (${a.price > 0 ? "+Rp ${a.price}" : "Gratis"})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _addons.remove(a);
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _addonNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Add-on',
                        hintText: 'Cth: Extra Shot',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _addonPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga (Rp)',
                        hintText: '5000',
                        isDense: true,
                        prefixText: 'Rp ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Tambah Add-on',
                    icon: const Icon(Icons.add_circle, color: AppTheme.accentOrange, size: 28),
                    onPressed: () {
                      final aName = _addonNameCtrl.text.trim();
                      final aPrice = int.tryParse(_addonPriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      if (aName.isNotEmpty) {
                        setState(() {
                          _addons.add(ProductAddon(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: aName,
                            price: aPrice,
                          ));
                          _addonNameCtrl.clear();
                          _addonPriceCtrl.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final price = int.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nama menu tidak boleh kosong!')),
              );
              return;
            }
            if (price <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Harga harus lebih dari Rp 0!')),
              );
              return;
            }

            final provider = context.read<StoreProvider>();
            final categoryId = _selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : null);
            final emoji = widget.product?.emoji ?? '';

            if (widget.product == null) {
              provider.addProduct(
                Product(
                  id: 0,
                  categoryId: categoryId,
                  name: name,
                  price: price,
                  emoji: emoji,
                  imageUrl: _imageUrl,
                  addOns: _addons,
                ),
              );
            } else {
              provider.editProduct(
                widget.product!.copyWith(
                  categoryId: categoryId,
                  name: name,
                  price: price,
                  imageUrl: _imageUrl,
                  addOns: _addons,
                ),
              );
            }
            Navigator.pop(context);
          },
          child: const Text('Simpan Menu', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _ManageCategoriesDialog extends StatefulWidget {
  const _ManageCategoriesDialog();

  @override
  State<_ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<_ManageCategoriesDialog> {
  final TextEditingController _addCategoryCtrl = TextEditingController();

  @override
  void dispose() {
    _addCategoryCtrl.dispose();
    super.dispose();
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final editCtrl = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Edit Nama Kategori'),
        content: TextField(
          controller: editCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, foregroundColor: Colors.white),
            onPressed: () {
              final newName = editCtrl.text.trim();
              if (newName.isNotEmpty) {
                context.read<StoreProvider>().editCategory(category.id, newName);
                Navigator.pop(dCtx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final categories = provider.categories;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.category_outlined, color: AppTheme.primaryNavy),
          SizedBox(width: 8),
          Text('Kelola Kategori Menu'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tambah Kategori
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addCategoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tambah Kategori Baru',
                        hintText: 'Cth: Minuman Dingin',
                        isDense: true,
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          provider.addCategory(val.trim());
                          _addCategoryCtrl.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: () {
                      final val = _addCategoryCtrl.text.trim();
                      if (val.isNotEmpty) {
                        provider.addCategory(val);
                        _addCategoryCtrl.clear();
                      }
                    },
                    child: const Text('Tambah'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Text(
                'DAFTAR KATEGORI SAAT INI',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: AppTheme.primaryNavy),
              ),
              const SizedBox(height: 8),
              if (categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Belum ada kategori.', style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
                )
              else
                ...categories.map((c) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderBlack.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryNavy),
                          tooltip: 'Edit Nama Kategori',
                          onPressed: () => _showEditCategoryDialog(context, c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          tooltip: 'Hapus Kategori',
                          onPressed: () {
                            final related = provider.products.where((p) => p.categoryId == c.id).toList();
                            if (related.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (dlgCtx) => AlertDialog(
                                  title: Text('Hapus Kategori "${c.name}"?'),
                                  content: Text(
                                    'Ada ${related.length} menu yang terhubung dengan kategori ini.\n\nPilih apakah Anda ingin menghapus kategorinya saja (menu tetap ada), atau menghapus menu di dalamnya juga.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dlgCtx),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(dlgCtx);
                                        provider.deleteCategory(c.id, deleteProductsUnderCategory: false);
                                      },
                                      child: const Text('Hapus Kategori Saja'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.dangerRed,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(dlgCtx);
                                        provider.deleteCategory(c.id, deleteProductsUnderCategory: true);
                                      },
                                      child: const Text('Hapus Kategori & Menunya'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              provider.deleteCategory(c.id);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}
