# PRD — Kasir Flutter: Aplikasi POS & Manajemen Antrean Digital Pager

| Metadata | Keterangan |
|---|---|
| **Nama Aplikasi** | Kasir Flutter (POS F&B + Digital Pager Terintegrasi) |
| **Lokasi Proyek** | `D:/Documents/Aksiva Studio/Kasir_Flutter` |
| **Versi** | 1.0.0 |
| **Status** | Konsep Matang & Disetujui / Siap Implementasi |
| **Platform Target** | Android Tablet (Utama) & Android Smartphone (Responsif) |
| **Target Pengguna** | Kasir, Barista, dan Pemilik Usaha F&B (Kedai Kopi, Restoran Cepat Saji, Food Court) |

---

## 1. Latar Belakang & Visi Produk

Aplikasi Kasir Flutter ini merupakan evolusi antarmuka kasir dari sistem **Digital Pager** yang telah divalidasi. Aplikasi ini menggabungkan pencatatan pesanan kasir (POS), manajemen katalog produk mandiri, rekap tren pemasukan F&B, dan kontrol pemanggilan nomor antrean pelanggan dalam satu aplikasi mobile/tablet yang responsif.

Dengan sistem ini:
1. **Onboarding Instan**: Pengguna pertama kali memasukkan data profil kedai (nama kedai, alamat, nomor telepon, dan catatan kustom di struk) yang langsung tersimpan dan otomatis menjadi kop struk.
2. **Katalog Produk Dinamis**: Pemilik/kasir dapat menambah, mengubah harga, dan mengubah status menu (Tersedia / Habis) secara instan ke database PostgreSQL terpusat.
3. **Struk Thermal On-Demand**: Mencetak struk via printer thermal Bluetooth hanya saat dibutuhkan (tidak otomatis buang kertas), lengkap dengan nomor antrean besar dan QR Code Pager Digital di bagian bawah.
4. **Cetak Ulang Struk**: Kasir dapat mencetak ulang struk kapan saja melalui menu Riwayat Transaksi tanpa mengubah atau membuat nomor antrean baru.
5. **Analitik & Tren Pemasukan**: Pemilik kedai dapat memantau omzet harian, grafik tren penjualan 7/30 hari, jam sibuk (peak hours), serta produk terlaris.
6. **Ekosistem Pager Realtime**: Terhubung langsung ke Web Tiket Pelanggan (`/t/:token`) dan Papan Antrean Dapur (`/queue`) yang sudah berjalan.

---

## 2. Alur Pengguna (User Flow)

### 2.1 Alur Pertama Kali Buka (Onboarding Profile Struk)
1. Aplikasi mendeteksi apakah data profil kedai sudah terisi di penyimpanan lokal.
2. Jika belum, tampilkan layar dialog penuh **"Pengaturan Profil Struk & Kedai"**:
   - Nama Kedai (Wajib)
   - Alamat Kedai (Wajib)
   - Nomor Telepon / WhatsApp (Wajib)
   - Pesan Tambahan Struk (Opsional, contoh: "Password WiFi: aksiva2026", "IG: @kedaiaksiva")
3. Pengguna menekan tombol **"Simpan & Masuk Kasir"**.
4. Data tersimpan di perangkat lokal dan disinkronkan ke backend.
5. Pada pembukaan aplikasi berikutnya, aplikasi langsung membuka layar Kasir (POS). Profil dapat diedit kembali kapan saja melalui menu Pengaturan.

### 2.2 Alur Transaksi Kasir (POS)
1. Kasir memilih kategori menu (Kopi, Non-Kopi, Makanan, Camilan).
2. Kasir mengetuk produk untuk menambahkannya ke keranjang pesanan.
3. Kasir dapat menambah catatan per item (misal: "Less sugar", "Tanpa es batu").
4. Memilih tipe pesanan (Dine In / Take Away) dan memasukkan nomor meja (jika Dine In).
5. Memilih metode pembayaran (Tunai, QRIS, Transfer Bank).
6. Jika Tunai, kasir memasukkan nominal uang diterima; aplikasi menghitung kembalian otomatis.
7. Kasir menekan tombol **"BAYAR & SELESAIKAN PESANAN"**.

### 2.3 Alur Konfirmasi Pembayaran & Cetak Struk
1. Begitu pembayaran tersimpan, muncul pop-up modal **"Pembayaran Berhasil"**:
   - Nomor Antrean besar (misal **A008**).
   - QR Code Pager Digital (Pelanggan dapat langsung scan dari layar kasir tanpa mencetak kertas).
   - Rincian ringkas pesanan & total bayar.
2. Kasir memiliki opsi:
   - **🖨️ Cetak Struk**: Menembak perintah cetak ke printer Bluetooth thermal (berisi kop kedai, rincian belanja, nomor antrean, dan QR Code pager).
   - **📢 Panggil Pelanggan**: Memanggil pager pelanggan langsung jika pesanan langsung jadi (misal takeaway).
   - **Transaksi Baru**: Menutup modal dan kembali ke katalog pesanan berikutnya.

### 2.4 Alur Cetak Ulang Struk (Reprint)
1. Kasir membuka menu **"Laporan & Riwayat Transaksi"**.
2. Kasir memilih salah satu transaksi pada daftar riwayat.
3. Menekan tombol **"🖨️ Cetak Ulang Struk"**.
4. Printer thermal mencetak struk dengan data asli dan token pager yang sama persis (tanpa membuat nomor antrean baru).

### 2.5 Alur Manajemen Produk (Kelola Menu)
1. Kasir/pemilik membuka menu **"Kelola Menu"**.
2. Menampilkan daftar seluruh produk yang dikelompokkan per kategori.
3. Setiap produk memiliki switch status **Tersedia / Habis**:
   - Jika diubah menjadi "Habis", produk tersebut otomatis nonaktif di layar kasir sehingga tidak bisa dipesan pelanggan.
4. Tombol **"Tambah Produk"**: form input nama, kategori, harga, dan icon/foto.
5. Aksi Edit / Hapus produk.

### 2.6 Alur Laporan & Tren Pemasukan
1. Kasir/pemilik membuka menu **"Laporan"**.
2. **Ringkasan Kartu (Metrics Cards)**:
   - Total Omzet Hari Ini (Rp)
   - Total Transaksi Hari Ini
   - Rata-rata Nilai Transaksi (Basket Size)
3. **Grafik Tren Penjualan**:
   - Grafik batang/garis omzet harian dalam rentang 7 hari terakhir atau 30 hari terakhir.
4. **Grafik Jam Sibuk (Peak Hours)**:
   - Distribusi frekuensi transaksi per jam (09.00 - 22.00) untuk mengetahui waktu paling ramai pengunjung.
5. **Top 5 Produk Terlaris**:
   - Daftar 5 menu paling laku beserta jumlah porsi dan kontribusi omzet.
6. **Daftar Riwayat Transaksi**:
   - Filter berdasarkan tanggal dan metode pembayaran.

---

## 3. Spesifikasi Tampilan & Responsivitas

Aplikasi wajib menerapkan prinsip **Responsive & Adaptive Layout**:

| Dimensi Layar | Mode | Layout Kasir | Navigasi |
|---|---|---|---|
| **Tablet (>= 600dp)** | Landscape | Split-Screen: Kiri 65% Katalog Menu, Kanan 35% Keranjang Aktif & Checkout | Navigation Rail (sisi kiri) |
| **Smartphone (< 600dp)** | Portrait | Fullscreen Katalog Menu + Bottom Floating Pill Bar Keranjang | Bottom Navigation Bar (sisi bawah) |

---

## 4. Format Struk Thermal (58mm & 80mm ESC/POS)

```
==========================================
            KEDAI KOPI AKSIVA
       Jl. Rinjani No. 12, Semarang
            Telp: 08562872671
==========================================
Tgl : 10/11/2026 14:35   Kasir: Kasir 1
Tipe: Dine In            Meja : 04
------------------------------------------
             NOMOR ANTREAN
                 A008
------------------------------------------
1x Kopi Susu Aren                  20.000
   * Less sugar
1x Croissant Butter                15.000
------------------------------------------
TOTAL                              35.000
TUNAI                              50.000
KEMBALIAN                          15.000
==========================================
          PAGER DIGITAL PESANAN
             [ QR CODE TIKET ]
   Scan QR dengan kamera HP Anda untuk
   memantau status & bel siap ambil
==========================================
        Password WiFi: aksiva2026
         Follow IG @kedaiaksiva
    Terima kasih atas kunjungan Anda!
==========================================
```

---

## 5. Non-Goals (Batasan Versi 1.0)
1. Tidak ada sistem multi-cabang/multi-tenant kompleks pada tahap ini (1 outlet utama).
2. Tidak ada autentikasi password/login bertingkat (bebas akses langsung sesuai kesepakatan).
3. Tidak ada integrasi auto-settlement payment gateway (pembayaran QRIS dicatat manual sebagai QRIS oleh kasir).
4. Tidak ada manajemen bahan baku resep (inventory recipe/HPP) pada rilis pertama.
