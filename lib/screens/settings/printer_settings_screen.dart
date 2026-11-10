import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/store_provider.dart';
import '../../services/storage_service.dart';
import '../../services/thermal_printer_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;
  String? _connectedMac;
  int _paperSize = 58;

  @override
  void initState() {
    super.initState();
    _connectedMac = StorageService.getPrinterAddress();
    _paperSize = StorageService.getPaperSize();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() => _isScanning = true);
    final isEnabled = await ThermalPrinterService.isBluetoothEnabled();
    if (!isEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Bluetooth mati. Silakan nyalakan Bluetooth terlebih dahulu.')),
        );
      }
      setState(() => _isScanning = false);
      return;
    }

    final list = await ThermalPrinterService.getPairedDevices();
    setState(() {
      _devices = list;
      _isScanning = false;
    });
  }

  Future<void> _connectDevice(BluetoothInfo info) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Menghubungkan ke ${info.name}...')),
    );

    final ok = await ThermalPrinterService.connect(info.macAdress);
    if (ok) {
      await StorageService.savePrinterSettings(
        macAddress: info.macAdress,
        name: info.name,
        paperSizeMm: _paperSize,
      );
      setState(() => _connectedMac = info.macAdress);
      if (mounted) {
        context.read<StoreProvider>().checkPrinterStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Terhubung ke ${info.name}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal terhubung ke ${info.name}')),
        );
      }
    }
  }

  Future<void> _testPrint() async {
    final isConn = await ThermalPrinterService.isConnected();
    if (!isConn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Printer belum terhubung. Hubungkan printer terlebih dahulu.')),
      );
      return;
    }

    // Send simple test text
    final text = 'TEST PRINT KASIR AKSIVA\nPrinter OK!\n\n\n';
    await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 2, text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🖨️ Perintah tes cetak berhasil dikirim!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSand,
      appBar: AppBar(
        title: const Text('Pengaturan Printer Thermal'),
        backgroundColor: AppTheme.primaryNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scanDevices,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status & Paper Size Card
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
                  const Text('Ukuran Kertas Thermal:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 58, label: Text('58 mm (Standar Portabel)')),
                      ButtonSegment(value: 80, label: Text('80 mm (Lebar)')),
                    ],
                    selected: {_paperSize},
                    onSelectionChanged: (set) {
                      setState(() => _paperSize = set.first);
                      if (_connectedMac != null) {
                        StorageService.savePrinterSettings(
                          macAddress: _connectedMac!,
                          name: StorageService.getPrinterName() ?? 'Printer',
                          paperSizeMm: _paperSize,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _testPrint,
                    icon: const Icon(Icons.print),
                    label: const Text('TES CETAK STRUK'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bluetooth Devices List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daftar Perangkat Bluetooth:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                if (_isScanning)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 10),

            if (_devices.isEmpty && !_isScanning)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderBlack, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    'Tidak ditemukan printer Bluetooth yang ter-pairing.\nNyalakan Bluetooth printer dan pairing terlebih dahulu di HP/Tablet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ..._devices.map((d) {
                final isConnected = _connectedMac == d.macAdress;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isConnected ? AppTheme.successGreen : AppTheme.borderBlack, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.print, color: isConnected ? AppTheme.successGreen : AppTheme.primaryNavy),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(d.macAdress, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      if (isConnected)
                        const Chip(label: Text('Terhubung', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))
                      else
                        ElevatedButton(
                          onPressed: () => _connectDevice(d),
                          child: const Text('Hubungkan'),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
