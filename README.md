# Henshin

**Point of Sale, fully offline.**

Henshin adalah aplikasi kasir (POS) mobile yang dibangun untuk berjalan **100% tanpa koneksi internet**. Seluruh data — produk, transaksi, stok, dan laporan — tersimpan lokal di perangkat menggunakan SQLite, sehingga aplikasi tetap cepat dan bisa diandalkan bahkan di lokasi tanpa sinyal sama sekali.

## Kenapa Henshin ada

Banyak usaha kecil dan menengah (warung, kafe, toko retail) masih mencatat transaksi secara manual atau menggunakan aplikasi kasir yang mengharuskan koneksi internet aktif setiap saat. Ketergantungan pada internet ini jadi masalah nyata di lokasi dengan sinyal tidak stabil, dan menimbulkan risiko operasional terhenti saat internet mati pada jam sibuk.

Henshin menghilangkan ketergantungan itu sepenuhnya. Tidak ada backend, tidak ada akun cloud, tidak ada sinkronisasi — hanya aplikasi kasir yang bekerja kapan pun dibutuhkan.

## Fitur utama

- **Transaksi kasir cepat** — pilih produk, hitung total dan kembalian otomatis, tanpa jeda loading
- **Manajemen produk & stok** — CRUD produk lengkap dengan kategori, harga modal (HPP), dan stok otomatis berkurang per penjualan
- **Riwayat & audit transaksi** — setiap transaksi tercatat lengkap dengan opsi void, membantu pemilik usaha mengaudit kinerja kasir
- **Dashboard & laporan** — ringkasan penjualan harian, tren 7 hari, dan produk terlaris
- **Cetak struk** — dukungan printer thermal Bluetooth, dengan opsi cetak ulang
- **Backup & restore manual** — satu-satunya safety net data karena aplikasi ini sepenuhnya offline
- **Scan barcode** — tambah produk ke keranjang lewat kamera, tanpa perlu hardware scanner tambahan

## Tech stack

| Layer | Teknologi |
|---|---|
| Framework | Flutter |
| State management | flutter_bloc + freezed |
| Database lokal | Drift (SQLite) |
| Navigasi | go_router (StatefulShellRoute) |
| Barcode scanner | mobile_scanner |
| Cetak struk | esc_pos_bluetooth |
| Arsitektur | Clean Architecture (presentation → domain → data) |

Lihat [Arsitektur](#arsitektur) untuk detail lebih lanjut.

## Quick start

### Prasyarat

- [Flutter SDK](https://docs.flutter.dev/get-started/install) versi stabil terbaru
- Android Studio / Xcode (tergantung target platform)
- Perangkat fisik atau emulator dengan kamera (untuk fitur scan barcode)

### Instalasi

```bash
# Clone repository
git clone https://github.com/krisnaCIHUUUY/henshinn.git
cd henshinn

# Install dependencies
flutter pub get

# Generate kode (Drift, Freezed, dsb)
dart run build_runner build --delete-conflicting-outputs

# Jalankan aplikasi
flutter run
```

### Build untuk rilis

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Struktur project

Henshin mengikuti **Clean Architecture** dengan pemisahan tegas antar layer:

```
lib/
├── core/                # Database, tema, router, utilitas lintas fitur
├── features/
│   ├── product/          # Manajemen produk & kategori
│   │   ├── data/          # Repository implementation, model
│   │   ├── domain/        # Entity, repository interface, usecase
│   │   └── presentation/  # Bloc, screen, widget
│   ├── transaction/       # Transaksi kasir & riwayat
│   ├── cart/              # State keranjang (in-memory)
│   ├── report/            # Laporan & dashboard
│   ├── backup/             # Backup & restore data
│   └── settings/           # Pengaturan toko & aplikasi
└── shared/                # Widget & extension reusable
```

Setiap fitur mengikuti alur dependency satu arah: `presentation → domain ← data`. Domain layer tidak bergantung pada Drift atau library eksternal apa pun, sehingga business logic mudah diuji secara terpisah.

## Arsitektur

Henshin dibangun **sepenuhnya offline** — sebuah keputusan sadar yang didokumentasikan dalam ADR internal proyek ini. Ringkasannya:

- **Tidak ada backend/server.** Semua data hidup dan mati di satu perangkat.
- **SQLite via Drift** dipilih karena type-safe query, reactive stream bawaan, dan dukungan transaksi atomic (penting untuk konsistensi stok saat transaksi berlangsung).
- **Uang disimpan sebagai integer** (rupiah utuh), bukan `double`, untuk menghindari floating-point error pada kalkulasi finansial.
- **Backup manual** menjadi satu-satunya mekanisme portabilitas data, karena tidak ada sinkronisasi otomatis ke cloud.

Trade-off ini cocok untuk skala penggunaan single-device/single-outlet. Kebutuhan multi-outlet atau sinkronisasi antar perangkat akan memerlukan perubahan arsitektur signifikan di masa depan.

## Kontribusi

Kontribusi terbuka untuk siapa saja yang ingin membantu mengembangkan Henshin.

1. Fork repository ini
2. Buat branch baru (`git checkout -b fitur/nama-fitur`)
3. Pastikan kode mengikuti struktur clean architecture yang sudah ada — lihat [Struktur project](#struktur-project)
4. Jalankan `dart run build_runner build --delete-conflicting-outputs` setelah mengubah file yang menggunakan Drift atau Freezed
5. Commit perubahan dengan pesan yang jelas
6. Buka Pull Request dengan deskripsi perubahan yang dilakukan

### Panduan kode

- Ikuti pemisahan layer domain/data/presentation — jangan letakkan logic Drift langsung di widget atau bloc
- Gunakan `Either<Failure, T>` untuk error handling di repository layer
- Setiap usecase baru sebaiknya punya satu tanggung jawab yang jelas
- Untuk perubahan skema database, tambahkan migration di `AppDatabase.migration`, jangan langsung ubah `schemaVersion` tanpa migration strategy
