import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../models/order.dart';
import '../../providers/store_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadReports();
    });
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
        title: const Text('Laporan & Tren Penjualan'),
        backgroundColor: AppTheme.primaryNavy,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentYellow,
          labelColor: AppTheme.accentYellow,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.insights), text: 'Tren & Statistik'),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Metric Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Omzet Hari Ini',
                  value: _formatRupiah(summary?.totalRevenue ?? 0),
                  color: AppTheme.successGreen,
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Transaksi',
                  value: '${summary?.totalOrders ?? 0}',
                  color: AppTheme.accentOrange,
                  icon: Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Rata-rata Order',
                  value: _formatRupiah(summary?.averageOrderValue ?? 0),
                  color: AppTheme.primaryNavy,
                  icon: Icons.shopping_basket,
                ),
              ),
            ],
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
                const Text(
                  '📈 Tren Penjualan Harian (7 Hari Terakhir)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: provider.revenueTrends.isEmpty
                      ? const Center(child: Text('Data tren belum tersedia'))
                      : BarChart(
                          BarChartData(
                            barGroups: provider.revenueTrends.asMap().entries.map((e) {
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.revenue.toDouble(),
                                    color: AppTheme.accentOrange,
                                    width: 16,
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
                                    if (idx < provider.revenueTrends.length) {
                                      final rawDate = provider.revenueTrends[idx].date;
                                      final parts = rawDate.split('-');
                                      return Text('${parts.length > 2 ? parts[2] : rawDate}', style: const TextStyle(fontSize: 10));
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
                  '🏆 5 Menu Paling Laris',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (topProducts.isEmpty)
                  const Text('Belum ada transaksi produk')
                else
                  ...topProducts.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Text('☕', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(p.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                            Text('${p.totalQuantity} porsi', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentOrange)),
                            const SizedBox(width: 16),
                            Text(_formatRupiah(p.totalRevenue), style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      )),
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
      padding: const EdgeInsets.all(14),
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
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  // Riwayat Transaksi & Cetak Ulang Struk
  Widget _buildHistoryTab(StoreProvider provider) {
    final txs = provider.transactions;
    if (txs.isEmpty) {
      return const Center(child: Text('Belum ada riwayat transaksi.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: txs.length,
      itemBuilder: (ctx, idx) {
        final order = txs[idx];
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
                child: Text(order.queueNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.items.length} item • ${order.orderType == "dine_in" ? "Dine In" : "Take Away"}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')} • ${order.paymentMethod.toUpperCase()}',
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
                tooltip: '🖨️ Cetak Ulang Struk',
                icon: const Icon(Icons.print, color: AppTheme.primaryNavy),
                onPressed: () async {
                  final ok = await provider.printOrderReceipt(order);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(ok ? '✅ Struk ${order.queueNumber} berhasil dicetak ulang!' : '⚠️ Gagal cetak ulang. Periksa koneksi printer.')),
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

  static String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
