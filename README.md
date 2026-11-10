# Kasir Flutter — POS F&B & Digital Pager Terintegrasi

Aplikasi kasir mobile modern berbasis **Flutter** untuk tablet dan smartphone, terintegrasi penuh dengan sistem **Digital Pager Realtime** dan basis data **PostgreSQL**.

---

## Fitur Utama

1. **Onboarding Profil Struk Instan**: Form pengaturan profil saat pertama kali buka (Nama Kedai, Alamat, No Telpon/WA, Teks Kustom Struk).
2. **Katalog POS Kasir Responsif**:
   - Tampilan Tablet: Layout 2 Kolom (Katalog 65% + Keranjang 35%).
   - Tampilan Smartphone: Layout 1 Kolom adaptif dengan floating bottom cart.
3. **Cetak Struk Thermal On-Demand**:
   - Mendukung printer thermal Bluetooth (ESC/POS 58mm & 80mm).
   - Cetak struk dilakukan manual melalui tombol layar (menghemat kertas).
   - Menampilkan QR Code Digital Pager di struk dan di layar kasir.
   - Fitur **Cetak Ulang Struk** dari menu Riwayat Transaksi.
4. **Kelola Produk & Status Ketersediaan**:
   - Tambah, edit, dan hapus menu F&B.
   - Switch status instan **Tersedia / Habis** langsung dari aplikasi.
5. **Laporan & Tren Penjualan**:
   - Kartu ringkasan omzet, total pesanan, dan rata-rata belanja.
   - Grafik tren penjualan harian (7 hari / 30 hari).
   - Analisis grafik jam sibuk (peak hours).
   - Daftar 5 produk terlaris.
   - Riwayat transaksi terperinci.
6. **Integrasi Digital Pager**:
   - Memanggil antrean pelanggan langsung dari kasir (`/api/v1/queue/:id/call`).
   - Pelanggan menerima notifikasi chime dan getar di web tiket (`/t/:token`).

---

## Struktur Folder

- `01-PRD.md` — Dokumen spesifikasi kebutuhan produk lengkap.
- `02-ARCHITECTURE.md` — Spesifikasi teknis, skema PostgreSQL, dan kontrak REST API.
- `lib/` — Kode sumber aplikasi Flutter.
- `pubspec.yaml` — Daftar pustaka dan dependensi Flutter.

---

## Menjalankan Aplikasi

Pastikan Flutter SDK telah terinstal di komputer.

```bash
# Masuk ke folder proyek
cd "D:/Documents/Aksiva Studio/Kasir_Flutter"

# Ambil paket dependensi
flutter pub get

# Jalankan di emulator / perangkat fisik
flutter run
```
