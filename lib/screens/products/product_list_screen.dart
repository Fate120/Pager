import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/product.dart';
import '../../providers/store_provider.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final products = provider.allProducts;

    return Scaffold(
      backgroundColor: AppTheme.backgroundSand,
      appBar: AppBar(
        title: const Text('Kelola Menu Produk'),
        backgroundColor: AppTheme.primaryNavy,
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
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSand,
                          border: Border.all(color: AppTheme.borderBlack, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(product.emoji, style: const TextStyle(fontSize: 24)),
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
                            Text(
                              _formatRupiah(product.price),
                              style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold),
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
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product != null ? product.price.toString() : '');
    final emojiCtrl = TextEditingController(text: product?.emoji ?? '☕');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product == null ? 'Tambah Menu Baru' : 'Edit Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Menu')),
            const SizedBox(height: 10),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga (Rp)')),
            const SizedBox(height: 10),
            TextField(controller: emojiCtrl, decoration: const InputDecoration(labelText: 'Emoji Ikon (cth: ☕, 🍵, 🍞)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = int.tryParse(priceCtrl.text) ?? 0;
              final emoji = emojiCtrl.text.trim().isEmpty ? '☕' : emojiCtrl.text.trim();
              if (name.isNotEmpty && price > 0) {
                final provider = context.read<StoreProvider>();
                if (product == null) {
                  provider.addProduct(Product(id: 0, name: name, price: price, emoji: emoji));
                } else {
                  provider.editProduct(product.copyWith(name: name, price: price, emoji: emoji));
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  static String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
