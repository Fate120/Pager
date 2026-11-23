import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../models/product.dart';
import '../../providers/store_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchForSelectedDate();
      final p = context.read<StoreProvider>();
      if (p.allProducts.isEmpty) {
        p.loadCatalog();
      }
    });
  }

  void _fetchForSelectedDate() {
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    context.read<StoreProvider>().loadReports(date: dateStr);
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchForSelectedDate();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundSand,
      appBar: AppBar(
        title: const Text('Laporan Penjualan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: AppTheme.primaryNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Laporan',
            onPressed: () => _fetchForSelectedDate(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentYellow,
          labelColor: AppTheme.accentYellow,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.insights), text: 'Analisis'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat Transaksi'),
          ],
        ),
      ),
      body: provider.isLoadingReports
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsTab(provider),
                _buildHistoryTab(provider),
              ],
            ),
    );
  }

  Widget _buildAnalyticsTab(StoreProvider provider) {
    final summary = provider.dailySummary;
    final topProducts = provider.topProducts;

    final cashRevenue = summary?.cashRevenue ?? 0;
    final qrisRevenue = summary?.qrisRevenue ?? 0;
    final totalRevenue = summary?.totalRevenue ?? (cashRevenue + qrisRevenue);
    final totalOrders = summary?.totalOrders ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Tanggal
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderBlack, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryNavy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSameDay(_selectedDate, DateTime.now())
                        ? 'Hari Ini (${_formatDate(_selectedDate)})'
                        : 'Tanggal: ${_formatDate(_selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  label: const Text('Ubah Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppTheme.primaryNavy,
                  ),
                  onPressed: () => _pickDate(context),
                ),
              ],
            ),
          ),

          // 1. Total Pemasukan (Di Atas)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderBlack, width: 2),
              boxShadow: AppTheme.brutalistShadow(offset: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppTheme.primaryNavy),
                    const SizedBox(width: 6),
                    const Text(
                      'Total Pemasukan',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                    ),
                    if (totalOrders > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentYellow,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderBlack, width: 1),
                        ),
                        child: Text(
                          '$totalOrders Transaksi',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatRupiah(totalRevenue),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.primaryNavy),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Pemasukan Tunai & QRIS (Bersebelahan, ukuran sama, teks di tengah)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Pemasukan Tunai',
                    value: _formatRupiah(cashRevenue),
                    color: AppTheme.successGreen,
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Pemasukan QRIS',
                    value: _formatRupiah(qrisRevenue),
                    color: AppTheme.accentOrange,
                    icon: Icons.qr_code_scanner,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Sales Trend Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderBlack, width: 2),
              boxShadow: AppTheme.brutalistShadow(offset: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        provider.trendPeriod == 'weekly'
                            ? 'Penjualan Mingguan'
                            : (provider.trendPeriod == 'monthly'
                                ? 'Penjualan Bulanan'
                                : 'Penjualan Harian'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Period Selector Chips
                Row(
                  children: [
                    _buildTrendPeriodChip(provider, 'daily', 'Harian'),
                    const SizedBox(width: 8),
                    _buildTrendPeriodChip(provider, 'weekly', 'Mingguan'),
                    const SizedBox(width: 8),
                    _buildTrendPeriodChip(provider, 'monthly', 'Bulanan'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: provider.revenueTrends.isEmpty
                      ? const Center(child: Text('Data tren belum tersedia'))
                      : BarChart(
                          BarChartData(
                            barGroups: provider.revenueTrends.asMap().entries.map((e) {
                              final rodWidth = provider.trendPeriod == 'monthly'
                                  ? 24.0
                                  : (provider.trendPeriod == 'weekly' ? 28.0 : 16.0);
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.revenue.toDouble(),
                                    color: AppTheme.accentOrange,
                                    width: rodWidth,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx >= 0 && idx < provider.revenueTrends.length) {
                                      final item = provider.revenueTrends[idx];
                                      final text = item.label.isNotEmpty ? item.label : item.date;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          text,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Top 5 Products
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderBlack, width: 2),
              boxShadow: AppTheme.brutalistShadow(offset: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu Terlaris',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (topProducts.isEmpty)
                  const Text('Belum ada transaksi produk')
                else
                  ...topProducts.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final p = entry.value;
                    Product? matchedProduct;
                    try {
                      matchedProduct = provider.allProducts.firstWhere(
                        (prod) => (p.productId > 0 && prod.id == p.productId) || prod.name.toLowerCase() == p.productName.toLowerCase(),
                      );
                    } catch (_) {}
                    final rawUrl = (p.imageUrl != null && p.imageUrl!.isNotEmpty) ? p.imageUrl : matchedProduct?.imageUrl;
                    final imageUrl = _resolveProductPhoto(p.productName, rawUrl);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: rank == 1 ? AppTheme.accentYellow : (rank <= 3 ? AppTheme.primaryNavy : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: rank == 1 ? Colors.black : (rank <= 3 ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildProductPhoto(imageUrl, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.totalQuantity} porsi terjual',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.accentOrange),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatRupiah(p.totalRevenue),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryNavy),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderBlack, width: 2),
        boxShadow: AppTheme.brutalistShadow(offset: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // Riwayat Transaksi & Cetak Ulang Struk
  Widget _buildHistoryTab(StoreProvider provider) {
    final txs = provider.transactions;
    if (txs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderBlack, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryNavy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isSameDay(_selectedDate, DateTime.now())
                          ? 'Hari Ini (${_formatDate(_selectedDate)})'
                          : 'Tanggal: ${_formatDate(_selectedDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.edit_calendar, size: 16),
                    label: const Text('Ubah Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppTheme.primaryNavy,
                    ),
                    onPressed: () => _pickDate(context),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(child: Text('Belum ada riwayat transaksi pada tanggal ini.')),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: txs.length + 1,
      itemBuilder: (ctx, idx) {
        if (idx == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderBlack, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryNavy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSameDay(_selectedDate, DateTime.now())
                        ? 'Hari Ini (${_formatDate(_selectedDate)}) • ${txs.length} Transaksi'
                        : '${_formatDate(_selectedDate)} • ${txs.length} Transaksi',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  label: const Text('Ubah Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppTheme.primaryNavy,
                  ),
                  onPressed: () => _pickDate(context),
                ),
              ],
            ),
          );
        }
        final order = txs[idx - 1];
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow,
                  border: Border.all(color: AppTheme.borderBlack, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.queueNumber.isNotEmpty ? order.queueNumber : '#${order.orderNo.split('-').last}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.customerName} • ${order.items.length} item • ${order.orderType == "dine_in" ? "Dine In" : "Take Away"}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${order.orderNo} • ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')} • ${order.paymentMethod.toUpperCase()}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                _formatRupiah(order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primaryNavy),
              ),
              const SizedBox(width: 8),
              // Tombol Cetak Ulang Struk
              IconButton(
                tooltip: 'Cetak Ulang Struk',
                icon: const Icon(Icons.print, color: AppTheme.primaryNavy),
                onPressed: () async {
                  final ok = await provider.printOrderReceipt(order);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(ok ? 'Struk ${order.queueNumber} berhasil dicetak ulang!' : 'Gagal cetak ulang. Periksa koneksi printer.')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendPeriodChip(StoreProvider provider, String period, String label) {
    final isSelected = provider.trendPeriod == period;
    return InkWell(
      onTap: () => provider.setTrendPeriod(period),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.borderBlack : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  String? _resolveProductPhoto(String productName, String? imageUrl) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) return imageUrl.trim();
    final lower = productName.toLowerCase();
    if (lower.contains('sederhana') || lower.contains('kopi sederhana')) {
      return 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=300&auto=format&fit=crop&q=80';
    } else if (lower.contains('aren')) {
      return 'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=300&auto=format&fit=crop&q=80';
    } else if (lower.contains('matcha')) {
      return 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=300&auto=format&fit=crop&q=80';
    } else if (lower.contains('americano')) {
      return 'https://images.unsplash.com/photo-1551030173-122aabc4489c?w=300&auto=format&fit=crop&q=80';
    } else if (lower.contains('kopi') || lower.contains('coffee') || lower.contains('latte') || lower.contains('cappuccino')) {
      return 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=300&auto=format&fit=crop&q=80';
    }
    return null;
  }

  Widget _buildProductPhoto(String? imageUrl, {double size = 44}) {
    Widget child;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      final trimmed = imageUrl.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        child = Image.network(
          trimmed,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackPhoto(size),
        );
      } else if (trimmed.startsWith('data:image')) {
        try {
          final bytes = base64Decode(trimmed.split(',').last);
          child = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackPhoto(size),
          );
        } catch (_) {
          child = _buildFallbackPhoto(size);
        }
      } else if (trimmed.startsWith('assets/')) {
        child = Image.asset(
          trimmed,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackPhoto(size),
        );
      } else {
        try {
          final bytes = base64Decode(trimmed);
          child = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackPhoto(size),
          );
        } catch (_) {
          child = _buildFallbackPhoto(size);
        }
      }
    } else {
      child = _buildFallbackPhoto(size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderBlack, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildFallbackPhoto(double size) {
    return Center(
      child: Icon(Icons.fastfood_outlined, size: size * 0.5, color: AppTheme.primaryNavy),
    );
  }

  static String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
