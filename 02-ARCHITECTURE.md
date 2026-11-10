# Arsitektur Teknis — Kasir Flutter & Backend PostgreSQL

Dokumen arsitektur ini mendefinisikan struktur aplikasi Flutter, skema basis data PostgreSQL, kontrak REST API backend, dan protokol cetak thermal ESC/POS.

---

## 1. Diagram Alur Sistem (System Architecture)

```
+-------------------------------------------------------------------------+
|                         KASIR FLUTTER APP                               |
|            (Tablet Android / Smartphone Android Responsif)              |
|                                                                         |
|  [Profil Kedai]    [Katalog POS]    [Kelola Menu]    [Laporan & Tren]   |
|         |                |                |                 |           |
|  Local Storage     Cetak Struk     CRUD Produk      Query Analitik      |
|  (SharedPreferences) (Bluetooth)                                        |
+---------+----------------+----------------+-----------------+-----------+
          |                |                |                 |
          |          ESC/POS Bytecode       |                 |
          |          (58mm / 80mm)          |                 |
          |                v                |                 |
          |        +-----------------+      |                 |
          |        | THERMAL PRINTER |      |                 |
          |        +-----------------+      |                 |
          |                                 |                 |
          +================ REST API =======+=================+
                                   |
                                   v
             +---------------------------------------------+
             |             NODE.JS EXPRESS BACKEND         |
             |                   (Railway)                 |
             |                                             |
             |   - /api/v1/config (Store Profile)          |
             |   - /api/v1/products (Menu & Kategori)      |
             |   - /api/v1/pos/orders (Checkout POS)       |
             |   - /api/v1/queue/* (Call & Complete)       |
             |   - /api/v1/reports/* (Trend & Analytics)   |
             +---------------------+-----------------------+
                                   |
                  +----------------+----------------+
                  |                                 |
                  v                                 v
        +-------------------+             +-------------------+
        |    POSTGRESQL     |             |    SSE STREAMS    |
        |     DATABASE      |             |  (Event-Stream)   |
        +-------------------+             +---------+---------+
                                                    |
                                    +---------------+---------------+
                                    |                               |
                                    v                               v
                          +-------------------+           +-------------------+
                          |  TIKET PELANGGAN  |           |   DAPUR DISPLAY   |
                          |    (/t/:token)    |           |     (/queue)      |
                          +-------------------+           +-------------------+
```

---

## 2. Skema Basis Data PostgreSQL

Skema berikut dirancang untuk kinerja tinggi, integritas referensial, dan query agregasi laporan penjualan yang instan.

```sql
-- 1. Tabel Profil Kedai
CREATE TABLE IF NOT EXISTS store_profiles (
    id SERIAL PRIMARY KEY,
    outlet_name VARCHAR(150) NOT NULL DEFAULT 'Kedai Kopi Aksiva',
    address TEXT,
    phone_number VARCHAR(50),
    receipt_custom_text TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabel Kategori Menu
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    emoji VARCHAR(20) DEFAULT '🍽️',
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabel Produk (Menu)
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    category_id INT REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(150) NOT NULL,
    price INT NOT NULL CHECK (price >= 0),
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    emoji VARCHAR(20) DEFAULT '☕',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabel Transaksi / Pesanan
CREATE TABLE IF NOT EXISTS orders (
    id VARCHAR(64) PRIMARY KEY,
    order_no INT NOT NULL,
    queue_number VARCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'preparing', -- preparing, ready, completed, cancelled
    order_type VARCHAR(20) NOT NULL DEFAULT 'dine_in', -- dine_in, take_away
    table_no VARCHAR(20),
    customer_name VARCHAR(100) DEFAULT 'Pelanggan',
    payment_method VARCHAR(20) NOT NULL, -- cash, qris, transfer
    cash_paid INT DEFAULT 0,
    total_amount INT NOT NULL,
    token VARCHAR(64) NOT NULL UNIQUE,
    call_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ready_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 5. Tabel Item Detail Transaksi
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id VARCHAR(64) REFERENCES orders(id) ON DELETE CASCADE,
    product_id INT REFERENCES products(id) ON DELETE SET NULL,
    item_name VARCHAR(150) NOT NULL,
    unit_price INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    subtotal INT NOT NULL,
    notes TEXT
);

-- Indeks untuk kecepatan query analitik & laporan
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
```

---

## 3. Spesifikasi REST API Backend

### 3.1 Profil & Konfigurasi Kedai
- `GET /api/v1/config` -> Mengambil data profil kedai.
- `POST /api/v1/config` -> Menyimpan/memperbarui data profil kedai (nama, alamat, no telp, teks struk).

### 3.2 Katalog & Manajemen Produk
- `GET /api/v1/categories` -> Daftar seluruh kategori.
- `GET /api/v1/products` -> Daftar seluruh produk beserta kategori dan status ketersediaannya.
- `POST /api/v1/products` -> Menambah produk baru (`{ categoryId, name, price, isAvailable, emoji }`).
- `PUT /api/v1/products/:id` -> Mengubah data produk atau toggle status ketersediaan.
- `DELETE /api/v1/products/:id` -> Menghapus produk.

### 3.3 Transaksi POS & Antrean
- `POST /api/v1/pos/orders` -> Membuat order baru:
  - Input: `{ paymentMethod, items, cashPaid, customerName, orderType, tableNo }`
  - Output: `{ orderId, queueNumber, ticketToken, ticketUrl, qrSvg, order }`
  - Trigger: Otomatis broadcast SSE ke Dapur & Pelanggan.
- `GET /api/v1/queue/active` -> Mengambil antrean aktif.
- `POST /api/v1/queue/:orderId/call` -> Memanggil antrean (status -> `ready`, increment `callCount`, broadcast SSE).
- `POST /api/v1/queue/:orderId/complete` -> Menyelesaikan antrean (status -> `completed`).

### 3.4 Laporan & Tren Penjualan
- `GET /api/v1/reports/summary?date=YYYY-MM-DD`
  - Mengembalikan: `{ totalRevenue, totalOrders, averageOrderValue }`
- `GET /api/v1/reports/trend?days=7`
  - Mengembalikan array: `[{ date: '2026-11-04', revenue: 450000, orders: 18 }, ...]`
- `GET /api/v1/reports/hourly?date=YYYY-MM-DD`
  - Mengembalikan distribusi transaksi per jam (jam 08:00 - 22:00) untuk analisis peak hours.
- `GET /api/v1/reports/top-products?limit=5`
  - Mengembalikan 5 menu terlaris beserta total porsi dan total nilai omzet.
- `GET /api/v1/reports/transactions?page=1&limit=20&date=YYYY-MM-DD`
  - Daftar transaksi lengkap untuk riwayat dan cetak ulang struk.

---

## 4. Struktur Proyek Flutter (`Kasir_Flutter`)

```
Kasir_Flutter/
├── android/
├── assets/
│   ├── fonts/
│   └── images/
├── lib/
│   ├── main.dart                      # Inisialisasi app, cek onboarding profil
│   ├── config/
│   │   ├── app_constants.dart         # API Base URL, default config
│   │   └── app_theme.dart             # Warna Neo-Brutalist & Typography
│   ├── models/
│   │   ├── store_profile.dart         # Model data profil kedai
│   │   ├── category.dart              # Model kategori
│   │   ├── product.dart               # Model produk
│   │   ├── cart_item.dart             # Model keranjang
│   │   ├── order.dart                 # Model transaksi order
│   │   └── report_analytics.dart      # Model analitik & tren
│   ├── providers/
│   │   ├── profile_provider.dart      # State profil kedai & onboarding
│   │   ├── catalog_provider.dart      # State produk, kategori, toggle ketersediaan
│   │   ├── cart_provider.dart         # State keranjang kasir & perhitungan
│   │   ├── queue_provider.dart        # State antrean & status panggilan
│   │   ├── reports_provider.dart      # State laporan tren & riwayat transaksi
│   │   └── printer_provider.dart      # State Bluetooth thermal printer & status
│   ├── services/
│   │   ├── api_service.dart           # HTTP Client REST API
│   │   ├── storage_service.dart       # SharedPreferences lokal
│   │   └── thermal_printer_service.dart # ESC/POS generator & Bluetooth stream
│   ├── screens/
│   │   ├── onboarding/
│   │   │   └── profile_setup_screen.dart # Form pertama kali buka
│   │   ├── pos/
│   │   │   ├── pos_screen.dart        # Layar kasir (Adaptive Tablet/Phone)
│   │   │   ├── widgets/
│   │   │   │   ├── product_grid.dart  # Grid katalog menu
│   │   │   │   ├── cart_panel.dart    # Panel keranjang belanja
│   │   │   │   └── receipt_modal.dart # Dialog struk, QR & tombol panggil
│   │   ├── queue/
│   │   │   └── queue_screen.dart      # Layar antrean & panggil kasir
│   │   ├── products/
│   │   │   ├── product_list_screen.dart # Kelola menu & toggle status
│   │   │   └── product_form_dialog.dart # Dialog tambah/edit produk
│   │   ├── reports/
│   │   │   ├── reports_screen.dart    # Dashboard omzet & grafik tren
│   │   │   ├── transaction_history_screen.dart # Riwayat & cetak ulang
│   │   │   └── widgets/
│   │   │       ├── revenue_chart.dart # Grafik tren penjualan (fl_chart)
│   │   │       └── peak_hours_chart.dart # Grafik jam sibuk
│   │   └── settings/
│   │       ├── settings_screen.dart   # Edit profil kedai
│   │       └── printer_settings_screen.dart # Scan & konek Bluetooth printer
│   └── utils/
│       ├── currency_formatter.dart    # Format Rupiah (Rp 20.000)
│       └── date_formatter.dart        # Format Waktu Indonesia
└── pubspec.yaml
```

---

## 5. Dependensi Utama (`pubspec.yaml`)

- `provider` / `flutter_riverpod`: Manajemen state reaktif.
- `http`: Komunikasi REST API ke backend.
- `shared_preferences`: Penyimpanan lokal profil kedai dan cache printer.
- `print_bluetooth_thermal` & `esc_pos_utils_plus`: Driver Bluetooth printer & generator ESC/POS command (teks tebal, nomor antrean besar, baris putus-putus, dan raster QR Code).
- `qr_flutter`: Render QR Code di layar tablet/HP kasir.
- `fl_chart`: Render grafik tren penjualan harian dan grafik jam ramai.
- `intl`: Format mata uang Indonesia (IDR) dan tanggal lokal.
