import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../models/order.dart';
import '../models/store_profile.dart';
import 'storage_service.dart';

class ThermalPrinterService {
  // Check Bluetooth state
  static Future<bool> isBluetoothEnabled() async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (e) {
      return false;
    }
  }

  // Get paired Bluetooth devices
  static Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      return [];
    }
  }

  // Connect to specific Bluetooth MAC address
  static Future<bool> connect(String macAddress) async {
    try {
      final connected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      return connected;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> disconnect() async {
    try {
      return await PrintBluetoothThermal.disconnect;
    } catch (e) {
      return false;
    }
  }

  // Generate ESC/POS byte commands for order receipt with Pager QR Code
  static Future<List<int>> generateReceiptBytes({
    required OrderModel order,
    required StoreProfile storeProfile,
    int paperSizeMm = 58,
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperSizeMm == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // 1. Header (Store Name, Address, Phone)
    bytes += generator.text(
      storeProfile.outletName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    if (storeProfile.address.isNotEmpty) {
      bytes += generator.text(
        storeProfile.address,
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    if (storeProfile.phoneNumber.isNotEmpty) {
      bytes += generator.text(
        'Telp/WA: ${storeProfile.phoneNumber}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.hr(ch: '=');

    // 2. Transaction Metadata
    final dateStr = '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';
    bytes += generator.row([
      PosColumn(text: 'Tgl : $dateStr', width: 6),
      PosColumn(text: 'Tipe: ${order.orderType == "dine_in" ? "Dine In" : "Take Away"}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (order.tableNo != null && order.tableNo!.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: 'Pelanggan: ${order.customerName}', width: 6),
        PosColumn(text: 'Meja: ${order.tableNo}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    } else {
      bytes += generator.text('Pelanggan: ${order.customerName}');
    }

    bytes += generator.hr(ch: '-');

    // 3. Queue Number (Big & Centered)
    bytes += generator.text(
      'NOMOR ANTREAN',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      order.queueNumber,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size3,
        width: PosTextSize.size3,
      ),
    );

    bytes += generator.hr(ch: '-');

    // 4. Items List
    for (var item in order.items) {
      bytes += generator.row([
        PosColumn(
          text: '${item.quantity}x ${item.itemName}',
          width: 8,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: _formatRupiah(item.subtotal),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      if (item.notes != null && item.notes!.isNotEmpty) {
        bytes += generator.text(
          '   * ${item.notes}',
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
    }

    bytes += generator.hr(ch: '-');

    // 5. Total & Payment
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: _formatRupiah(order.totalAmount),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Metode Bayar: ${order.paymentMethod.toUpperCase()}', width: 6),
      PosColumn(
        text: order.paymentMethod == 'cash' ? _formatRupiah(order.cashPaid) : _formatRupiah(order.totalAmount),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (order.paymentMethod == 'cash' && order.cashPaid > order.totalAmount) {
      bytes += generator.row([
        PosColumn(text: 'KEMBALIAN', width: 6),
        PosColumn(
          text: _formatRupiah(order.cashPaid - order.totalAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr(ch: '=');

    // 6. Digital Pager Section & QR Code
    final customerUrl = order.ticketUrl ?? '${StorageService.getBaseUrl()}/t/${order.token}';
    bytes += generator.text(
      'PAGER DIGITAL PESANAN',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    
    // QR Code
    bytes += generator.qrcode(
      customerUrl,
      size: QRSize.size4,
      cor: QRCorrection.M,
    );

    bytes += generator.text(
      'Scan QR di atas dengan kamera HP',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'untuk pantau pesanan & bel siap ambil',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.hr(ch: '=');

    // 7. Custom Footer Notes (WiFi, Social media, etc.)
    if (storeProfile.receiptCustomText.isNotEmpty) {
      bytes += generator.text(
        storeProfile.receiptCustomText,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    bytes += generator.text(
      'Terima Kasih Atas Kunjungan Anda!',
      styles: const PosStyles(align: PosAlign.center),
    );

    // Feed paper & Cut
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  // Print Order to connected Bluetooth printer
  static Future<bool> printReceipt({
    required OrderModel order,
    required StoreProfile storeProfile,
  }) async {
    final isConn = await isConnected();
    if (!isConn) {
      final savedMac = StorageService.getPrinterAddress();
      if (savedMac != null && savedMac.isNotEmpty) {
        final reconnected = await connect(savedMac);
        if (!reconnected) return false;
      } else {
        return false;
      }
    }

    final paperSize = StorageService.getPaperSize();
    final bytes = await generateReceiptBytes(
      order: order,
      storeProfile: storeProfile,
      paperSizeMm: paperSize,
    );

    final res = await PrintBluetoothThermal.writeBytes(bytes);
    return res;
  }

  static String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
