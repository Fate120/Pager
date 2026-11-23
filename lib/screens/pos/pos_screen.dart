import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/store_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/product_image_widget.dart';
import '../products/product_list_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/printer_settings_screen.dart';
import '../settings/settings_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _cashPaidController = TextEditingController();
  final TextEditingController _tableNoController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  String _paymentMethod = 'cash';

  @override
  void dispose() {
    _cashPaidController.dispose();
    _tableNoController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  void _onNavSelected(int index) {
    if (index == _currentNavIndex) return;
    if (index == 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProductListScreen()));
    } else if (index == 2) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
    } else if (index == 3) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: AppTheme.backgroundSand,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Consumer<StoreProvider>(
                builder: (_, p, __) => Text(
                  p.profile.outletName,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (isTablet) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow,
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'POS KASIR',
                  style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Tombol Antrean Aktif
          Consumer<StoreProvider>(
            builder: (ctx, p, _) {
              final count = p.activeQueue.length;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: InkWell(
                  onTap: () => _showActiveQueueDialog(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: count > 0 ? AppTheme.accentOrange : Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_alt, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Antrean: $count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Pengaturan Printer Bluetooth',
            icon: Consumer<StoreProvider>(
              builder: (_, p, __) => Icon(
                p.isPrinterConnected ? Icons.print : Icons.print_disabled,
                color: p.isPrinterConnected ? Colors.greenAccent : Colors.white70,
              ),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Pengaturan Usaha',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isTablet
          ? null
          : BottomNavigationBar(
              currentIndex: _currentNavIndex,
              selectedItemColor: AppTheme.primaryNavy,
              unselectedItemColor: AppTheme.textMuted,
              onTap: _onNavSelected,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
                BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
              ],
            ),
      body: Row(
        children: [
          // Tablet Navigation Rail
          if (isTablet)
            NavigationRail(
              selectedIndex: _currentNavIndex,
              onDestinationSelected: _onNavSelected,
              backgroundColor: AppTheme.primaryNavy,
              selectedIconTheme: const IconThemeData(color: AppTheme.accentYellow),
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedLabelTextStyle: const TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.point_of_sale), label: Text('Kasir')),
                NavigationRailDestination(icon: Icon(Icons.restaurant_menu), label: Text('Menu')),
                NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Laporan')),
                NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Setting')),
              ],
            ),

          // Main POS Area
          Expanded(
            child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
          ),
        ],
      ),
    );
  }

  // Tablet: Split Screen (Catalog 65% + Cart 35%)
  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 65,
          child: _buildCatalogView(),
        ),
        Container(width: 2, color: AppTheme.borderBlack),
        Expanded(
          flex: 35,
          child: _buildCartView(),
        ),
      ],
    );
  }

  // Phone: Full Catalog + Floating Bottom Cart Bar
  Widget _buildPhoneLayout() {
    final cartCount = context.watch<StoreProvider>().cartItemCount;
    final cartTotal = context.watch<StoreProvider>().cartTotal;

    return Stack(
      children: [
        _buildCatalogView(),
        if (cartCount > 0)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: _showPhoneCartBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderBlack, width: 2),
                  boxShadow: AppTheme.brutalistShadow(offset: 4),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$cartCount item',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatRupiah(cartTotal),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const Text('BAYAR', style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Catalog (Categories + Product Grid)
  Widget _buildCatalogView() {
    final provider = context.watch<StoreProvider>();
    final categories = provider.categories;
    final products = provider.filteredProducts;

    return Column(
      children: [
        // Category Pills Bar
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderBlack, width: 2)),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildCategoryPill(
                label: 'Semua Menu',
                isSelected: provider.selectedCategoryId == null,
                onTap: () => provider.selectCategory(null),
              ),
              ...categories.map((c) => _buildCategoryPill(
                    label: c.name,
                    isSelected: provider.selectedCategoryId == c.id,
                    onTap: () => provider.selectCategory(c.id),
                  )),
            ],
          ),
        ),

        // Product Grid
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('Belum ada menu di kategori ini.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, idx) => _buildProductCard(products[idx]),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryNavy : AppTheme.backgroundSand,
            border: Border.all(color: AppTheme.borderBlack, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? AppTheme.brutalistShadow(offset: 2) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final provider = context.read<StoreProvider>();

    return InkWell(
      onTap: product.isAvailable ? () => _handleProductTap(product) : null,
      child: Container(
        decoration: BoxDecoration(
          color: product.isAvailable ? Colors.white : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderBlack, width: 2),
          boxShadow: product.isAvailable ? AppTheme.brutalistShadow(offset: 3) : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ProductImageWidget(
                product: product,
                size: 72,
                borderRadius: 8,
              ),
            ),
            const Spacer(),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: product.isAvailable ? AppTheme.textDark : AppTheme.textMuted,
              ),
            ),
            if (product.addOns.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+ ${product.addOns.length} Opsi Add-on',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatRupiah(product.price),
                  style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                if (!product.isAvailable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('HABIS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: product.addOns.isNotEmpty ? const Color(0xFFEFF6FF) : AppTheme.accentYellow,
                      border: Border.all(color: Colors.black, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(product.addOns.isNotEmpty ? Icons.tune : Icons.add, size: 16),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleProductTap(Product product) {
    if (product.addOns.isNotEmpty) {
      _showProductCustomizationModal(product);
    } else {
      context.read<StoreProvider>().addToCart(product);
    }
  }

  void _showProductCustomizationModal(Product product) {
    final provider = context.read<StoreProvider>();
    final selectedAddons = <ProductAddon>[];
    int quantity = 1;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final addOnsTotal = selectedAddons.fold(0, (sum, a) => sum + a.price);
          final currentUnitPrice = product.price + addOnsTotal;
          final currentSubtotal = currentUnitPrice * quantity;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProductImageWidget(product: product, size: 56, borderRadius: 8),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            Text(
                              _formatRupiah(product.price),
                              style: const TextStyle(
                                color: AppTheme.accentOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'PILIH ADD-ON / TOPPING / VARIAN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...product.addOns.map((addon) {
                    final isChecked = selectedAddons.any((a) => a.id == addon.id);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppTheme.accentOrange,
                      title: Text(
                        addon.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        addon.price > 0 ? '+ ${_formatRupiah(addon.price)}' : 'Gratis',
                        style: TextStyle(
                          color: addon.price > 0 ? AppTheme.accentOrange : AppTheme.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      value: isChecked,
                      onChanged: (bool? val) {
                        setModalState(() {
                          if (val == true) {
                            selectedAddons.add(addon);
                          } else {
                            selectedAddons.removeWhere((a) => a.id == addon.id);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Catatan Khusus (Opsional)',
                      hintText: 'Cth: Less sugar, sambal dipisah...',
                      prefixIcon: const Icon(Icons.edit_note),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderBlack, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: quantity > 1
                                  ? () => setModalState(() => quantity--)
                                  : null,
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () => setModalState(() => quantity++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            provider.addToCart(
                              product,
                              notes: notesController.text.trim(),
                              selectedAddOns: selectedAddons,
                              quantity: quantity,
                            );
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'TAMBAH — ${_formatRupiah(currentSubtotal)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Cart View
  Widget _buildCartView() {
    final provider = context.watch<StoreProvider>();
    final cart = provider.cart;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pesanan Kasir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              if (cart.isNotEmpty)
                TextButton(
                  onPressed: () => provider.clearCart(),
                  child: const Text('Kosongkan', style: TextStyle(color: AppTheme.dangerRed, fontSize: 12)),
                ),
            ],
          ),
          const Divider(color: AppTheme.borderBlack, thickness: 1.5),

          // Order type selection & Table No
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'dine_in', label: Text('Dine In')),
                    ButtonSegment(value: 'take_away', label: Text('Take Away')),
                  ],
                  selected: {provider.orderType},
                  onSelectionChanged: (set) => provider.setOrderType(set.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (provider.orderType == 'dine_in')
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _tableNoController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Meja',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => provider.setTableNo(val),
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan (Opsional)',
                hintText: 'Default: Pelanggan-<No.Antrean>',
                isDense: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline, size: 18),
              ),
              onChanged: (val) => provider.setCustomerName(val),
            ),
          ),

          // Items List
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text('Keranjang masih kosong\nPilih menu untuk memesan', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
                  )
                : ListView.separated(
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) => _buildCartItemTile(cart[idx]),
                  ),
          ),

          // Payment & Checkout
          if (cart.isNotEmpty) ...[
            const Divider(color: AppTheme.borderBlack, thickness: 1.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL BELANJA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                Text(
                  _formatRupiah(provider.cartTotal),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryNavy),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () => _openCheckoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('SELESAIKAN & BAYAR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartItem item) {
    final provider = context.read<StoreProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (item.selectedAddOns.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Text(
                      item.formattedAddOns,
                      style: const TextStyle(fontSize: 11, color: AppTheme.accentOrange, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (item.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      'Catatan: ${item.notes}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                    ),
                  ),
                Text(_formatRupiah(item.unitPrice), style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => provider.updateQuantity(item, -1),
              ),
              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => provider.updateQuantity(item, 1),
              ),
            ],
          ),
          Text(_formatRupiah(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _showPhoneCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _buildCartView(),
      ),
    );
  }

  // Checkout Dialog (Payment selection, Cash Calculation, & Submit)
  void _openCheckoutDialog(BuildContext context) {
    final provider = context.read<StoreProvider>();
    final total = provider.cartTotal;
    _cashPaidController.text = total.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppTheme.borderBlack, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Pembayaran Pesanan', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Total Tagihan: ${_formatRupiah(total)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryNavy)),
                const SizedBox(height: 16),
                TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pelanggan (Opsional)',
                    hintText: 'Default: Pelanggan-<No.Antrean>',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Pilih Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['cash', 'qris', 'transfer'].map((m) {
                    final isSel = _paymentMethod == m;
                    return ChoiceChip(
                      label: Text(m.toUpperCase()),
                      selected: isSel,
                      onSelected: (val) => setDialogState(() => _paymentMethod = m),
                    );
                  }).toList(),
                ),
                if (_paymentMethod == 'cash') ...[
                  const SizedBox(height: 16),
                  const Text('Nominal Uang Tunai Diterima:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _cashPaidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(border: OutlineInputBorder(), prefixText: 'Rp '),
                    onChanged: (v) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (_) {
                    final cash = int.tryParse(_cashPaidController.text) ?? 0;
                    final change = cash - total;
                    return Text(
                      'Kembalian: ${_formatRupiah(change >= 0 ? change : 0)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: change >= 0 ? AppTheme.successGreen : AppTheme.dangerRed),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final cashPaid = int.tryParse(_cashPaidController.text) ?? total;
                final custName = _customerNameController.text.trim();
                Navigator.of(ctx).pop();
                final order = await provider.checkout(
                  paymentMethod: _paymentMethod,
                  cashPaid: cashPaid,
                  customerName: custName,
                );
                _customerNameController.clear();
                _tableNoController.clear();
                if (order != null && mounted) {
                  _showOrderSuccessModal(context, order);
                } else if (order == null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal membuat antrean. Periksa koneksi backend di Pengaturan.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('KONFIRMASI BAYAR'),
            ),
          ],
        ),
      ),
    );
  }

  // Modal Struk & Pager Digital Berhasil
  void _showOrderSuccessModal(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.borderBlack, width: 2.5),
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pembayaran Berhasil', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.successGreen, fontSize: 18)),
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textMuted),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(order.queueNumber, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.primaryNavy)),
              const Text('Nomor Antrean Pelanggan', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                height: 160,
                child: QrImageView(
                  data: order.ticketUrl ?? 'http://localhost:3100/t/${order.token}',
                  version: QrVersions.auto,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Pelanggan dapat scan QR di atas dengan HP', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.print, size: 18, color: Colors.white),
                        label: const Text('Cetak Struk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          side: const BorderSide(color: AppTheme.borderBlack, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final ok = await context.read<StoreProvider>().printOrderReceipt(order);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(ok ? 'Struk tercetak!' : 'Gagal mencetak struk. Cek koneksi printer.')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.campaign, size: 18, color: Colors.white),
                        label: const Text('Panggil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          side: const BorderSide(color: AppTheme.borderBlack, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          await context.read<StoreProvider>().callQueue(order.id);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Sinyal panggilan terkirim ke HP pelanggan!')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
                  label: const Text(
                    'Transaksi Baru',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    side: const BorderSide(color: AppTheme.borderBlack, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showActiveQueueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer<StoreProvider>(
        builder: (dialogCtx, provider, _) {
          final queue = provider.activeQueue;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppTheme.borderBlack, width: 2.5),
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt, color: AppTheme.primaryNavy),
                    const SizedBox(width: 8),
                    Text(
                      'Antrean Aktif (${queue.length})',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Segarkan',
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => provider.loadActiveQueue(),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 520,
              child: queue.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada antrean yang sedang disiapkan.',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pesanan baru dari kasir akan otomatis muncul di sini.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: queue.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, idx) {
                        final item = queue[idx];
                        final isCalled = item.callCount > 0;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isCalled ? AppTheme.accentYellow.withValues(alpha: 0.15) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderBlack, width: 2),
                            boxShadow: AppTheme.brutalistShadow(offset: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Nomor Antrean & Info Pelanggan di Atas
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryNavy,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.borderBlack, width: 1.5),
                                    ),
                                    child: Text(
                                      item.queueNumber,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.customerName} • ${item.orderType == 'dine_in' ? 'Dine In' : 'Take Away'}${item.tableNo != null && item.tableNo!.isNotEmpty ? ' (Meja ${item.tableNo})' : ''}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        if (isCalled) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Sudah dipanggil ${item.callCount}x',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // 2. Ringkasan Menu
                              Text(
                                item.items.map((it) => '${it.quantity}x ${it.name}').join(', '),
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),

                              // 3. Tombol Lihat QR dan Cetak Struk Bersebelahan
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.qr_code_2, size: 16),
                                      label: const Text('Lihat QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        side: const BorderSide(color: AppTheme.primaryNavy, width: 1.5),
                                        foregroundColor: AppTheme.primaryNavy,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onPressed: () => _showQueueDetailDialog(context, item),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.print_outlined, size: 16),
                                      label: const Text('Cetak Struk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        side: const BorderSide(color: AppTheme.primaryNavy, width: 1.5),
                                        foregroundColor: AppTheme.primaryNavy,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onPressed: () => _showReceiptPreviewDialog(context, item),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 4. Tombol Panggil dan Selesai Bersebelahan di Paling Bawah
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.campaign, size: 16, color: Colors.white),
                                      label: const Text('Panggil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentOrange,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        elevation: 0,
                                        side: const BorderSide(color: AppTheme.borderBlack, width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onPressed: () async {
                                        await provider.callQueue(item.id);
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(content: Text('Memanggil antrean ${item.queueNumber}...')),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                                      label: const Text('Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.successGreen,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        elevation: 0,
                                        side: const BorderSide(color: AppTheme.borderBlack, width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onPressed: () async {
                                        await provider.completeQueue(item.id);
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(content: Text('Antrean ${item.queueNumber} selesai diambil!')),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showQueueDetailDialog(BuildContext context, OrderModel order) {
    final customerUrl = order.ticketUrl ?? '${StorageService.getBaseUrl()}/t/${order.token}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.borderBlack, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: AppTheme.primaryNavy),
                const SizedBox(width: 8),
                Text('QR Tiket ${order.queueNumber}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                order.queueNumber,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.primaryNavy),
              ),
              Text(
                '${order.customerName} • ${order.orderType == "dine_in" ? "Dine In" : "Take Away"}${order.tableNo != null && order.tableNo!.isNotEmpty ? " (Meja ${order.tableNo})" : ""}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderBlack, width: 2),
                  boxShadow: AppTheme.brutalistShadow(offset: 3),
                ),
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: QrImageView(
                    data: customerUrl,
                    version: QrVersions.auto,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Scan QR di atas untuk membuka Tiket Pager Digital di HP',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: customerUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link tiket disalin ke clipboard!')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link, size: 16, color: AppTheme.primaryNavy),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          customerUrl,
                          style: const TextStyle(fontSize: 11, color: AppTheme.primaryNavy, decoration: TextDecoration.underline),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.copy, size: 14, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.print_outlined),
            label: const Text('Cetak Struk'),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryNavy)),
            onPressed: () {
              Navigator.pop(ctx);
              _showReceiptPreviewDialog(context, order);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showReceiptPreviewDialog(BuildContext context, OrderModel order) {
    final provider = context.read<StoreProvider>();
    final profile = provider.profile;
    final customerUrl = order.ticketUrl ?? '${StorageService.getBaseUrl()}/t/${order.token}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.borderBlack, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: AppTheme.primaryNavy),
                SizedBox(width: 8),
                Text('Struk Pembelian', style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    profile.outletName.isNotEmpty ? profile.outletName : 'Kedai Kopi Aksiva',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (profile.address.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        profile.address,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (profile.phoneNumber.isNotEmpty)
                    Text(
                      'Telp/WA: ${profile.phoneNumber}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  const Divider(height: 16, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('No: ${order.orderNo}', style: const TextStyle(fontSize: 11)),
                      Text(
                        '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pelanggan: ${order.customerName}', style: const TextStyle(fontSize: 11)),
                      Text(order.orderType == 'dine_in' ? 'Dine In' : 'Take Away', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  if (order.tableNo != null && order.tableNo!.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Meja: ${order.tableNo}', style: const TextStyle(fontSize: 11)),
                    ),
                  const Divider(height: 16, thickness: 1),
                  const Text('NOMOR ANTREAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(
                    order.queueNumber,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.primaryNavy),
                  ),
                  const Divider(height: 16, thickness: 1),
                  ...order.items.map((it) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${it.quantity}x ${it.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(_formatRupiah(it.subtotal), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          if (it.notes != null && it.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text('* ${it.notes}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
                            ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 16, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      Text(_formatRupiah(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ],
                  ),
                  if (order.paymentMethod.toLowerCase() == 'qris') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Metode Bayar', style: TextStyle(fontSize: 11)),
                        Text('QRIS (LUNAS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bayar (TUNAI)', style: TextStyle(fontSize: 11)),
                        Text(_formatRupiah(order.cashPaid > 0 ? order.cashPaid : order.totalAmount), style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    if (order.cashPaid > order.totalAmount)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kembalian', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(_formatRupiah(order.cashPaid - order.totalAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                  ],
                  const Divider(height: 16, thickness: 1),
                  const Text('PAGER DIGITAL PESANAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: QrImageView(data: customerUrl, version: QrVersions.auto),
                  ),
                  const SizedBox(height: 4),
                  const Text('Scan untuk info status pesanan', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  if (profile.receiptCustomText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(profile.receiptCustomText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Cetak Struk'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
            onPressed: () async {
              final ok = await provider.printOrderReceipt(order);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Struk sedang dicetak...' : 'Perintah cetak dikirim ke printer thermal.'),
                  ),
                );
              }
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
