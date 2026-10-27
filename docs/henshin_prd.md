# Blueprint MVP Henshin

**PRD dan Rekomendasi Arsitektur & Tech Stack**
Aplikasi POS Offline Berbasis Flutter untuk Usaha Kecil dan Menengah

| | |
|---|---|
| **Versi** | 1.0 (Final) |
| **Tanggal** | 7 Oktober 2026 |
| **Sumber kebutuhan** | Laporan Requirement Elicitation PT RONGAWI (wawancara dengan pemilik toko, Troso, Jepara, 3 Oktober 2026) |
| **Disusun untuk** | Solo developer / tim kecil |
| **Isi dokumen** | PRD (fitur inti, user story, di luar scope, metrik), perbandingan dan rekomendasi stack, rencana eksekusi 8 minggu |

---

## Ringkasan Eksekutif

Henshin adalah aplikasi Point of Sale (POS) Android yang berjalan sepenuhnya offline untuk satu toko dan satu perangkat. Tujuan MVP adalah mengganti nota tulis tangan dengan pencatatan digital yang cepat, akurat, dan aman, tanpa bergantung pada internet.

MVP terdiri dari **lima fitur inti**: transaksi kasir dan struk, produk dan stok, riwayat dan void ber-PIN, dashboard dan laporan, serta backup dan restore. Stack yang direkomendasikan adalah **Flutter + Cubit + Drift (SQLite)** dengan arsitektur **feature-first + repository**, dibangun dalam 8 minggu oleh satu developer.

### Konteks proyek

| | |
|---|---|
| **Developer** | 1 orang; satu-satunya anggota berpengalaman Flutter. Terbiasa Bloc/Cubit, SQL tingkat dasar. |
| **Kapasitas** | ±5 jam per hari. Dokumen ini mengasumsikan 5 hari per minggu, sehingga ±200 jam dalam 8 minggu. |
| **Deadline** | 2 bulan sejak dokumen ini. |
| **Target kualitas** | Dipakai sungguhan setiap hari di toko, termasuk backup data. |
| **Perangkat** | Android fisik sudah tersedia. Printer thermal Bluetooth belum tersedia. |
| **Anggota lain** | 4 orang tanpa pengalaman Flutter; diberi tugas non-coding (lihat Bagian 3). |

> **Catatan asumsi kapasitas.** Angka ±5 jam dibaca sebagai 5 jam per hari. Jika maksudnya 5 jam per minggu (total ±40 jam), scope harus dipotong drastis: hanya F1, F2, dan F5 yang realistis.

### Temuan penting dari laporan elicitation

- **Perangkat pendukung belum lengkap.** Printer thermal Bluetooth belum ada, padahal cetak struk bergantung padanya. Android fisik wajib untuk menguji kamera barcode dan Bluetooth.
- **Scan barcode adalah kebutuhan baru** (FR-05) yang belum ada di deskripsi cakupan awal dan kini masuk MVP.
- **Backup/restore dan ekspor Excel** dinyatakan boleh dibatasi oleh pemilik. Karena Henshin offline-only dan akan dipakai harian, backup/restore dinaikkan menjadi fitur inti, sedangkan ekspor Excel tetap di luar scope.

---

# Bagian 1. Product Requirements Document (PRD)

## 1.1 Ringkasan Produk

| | |
|---|---|
| **Produk** | Henshin, POS offline Android untuk satu toko dan satu perangkat |
| **Pengguna** | **Pemilik toko** (pengambil keputusan, pemegang PIN) dan **Kasir** (anak/anggota keluarga pemilik) |
| **Masalah inti** | Nota ditulis tangan, kasir tidak hafal harga, tidak ada riwayat dan pengawasan transaksi, stok baru dicatat setelah habis, tidak ada laporan berkala |
| **Nilai utama** | Transaksi cepat, harga selalu benar, stok terpantau, pemilik bisa memeriksa transaksi dan melihat laba kapan saja |

## 1.2 Fitur Inti MVP (maksimal 5)

| # | Fitur | Isi | Rujukan |
|---|---|---|---|
| F1 | **Transaksi Kasir dan Struk** | Keranjang, cari produk atau scan barcode, total dan kembalian otomatis, simpan di database lokal, cetak struk | FR-01, 02, 03, 05, 13 |
| F2 | **Produk dan Stok** | CRUD produk (nama, barcode, kategori, harga jual, harga modal), stok turun otomatis, input restok, peringatan stok menipis | FR-04, 06, 07 |
| F3 | **Riwayat, Void, dan PIN** | Riwayat transaksi beserta detail dan status, void dengan PIN dan alasan, cetak ulang struk | FR-08, 09, 10, 13 |
| F4 | **Dashboard dan Laporan** | Omzet, laba kotor, produk terlaris, laporan per rentang tanggal | FR-11, 12 |
| F5 | **Backup dan Restore** | Ekspor dan impor seluruh data toko, pengingat backup berkala | FR-14 |

*Cetak struk digabung ke alur F1 dan F3 agar jumlah fitur tetap lima. Ekspor Excel (FR-15) dikeluarkan dari MVP sesuai permintaan pemilik.*

## 1.3 User Story

Format: Sebagai [role], saya mau [aksi], supaya [hasil].

### F1. Transaksi Kasir dan Struk

- **US-1.1** Sebagai kasir, saya mau memindai barcode atau mengetik nama produk untuk menambahkannya ke keranjang, supaya saya tidak perlu mengingat atau menanyakan harga.
- **US-1.2** Sebagai kasir, saya mau total dan kembalian dihitung otomatis setelah memasukkan uang diterima, supaya tidak ada salah hitung dan pembeli tidak menunggu.
- **US-1.3** Sebagai kasir, saya mau mengubah jumlah atau menghapus item sebelum bayar, supaya salah input bisa dikoreksi tanpa membatalkan seluruh transaksi.
- **US-1.4** Sebagai kasir, saya mau struk tercetak setelah pembayaran, dan transaksi tetap tersimpan walau printer gagal terhubung, supaya pembeli mendapat bukti dan antrean tidak macet.
- **US-1.5** Sebagai pemilik, saya mau transaksi berjalan tanpa internet, supaya toko tetap bisa berjualan kapan pun.

### F2. Produk dan Stok

- **US-2.1** Sebagai pemilik, saya mau mendaftarkan produk beserta harga jual dan harga modal, supaya ada daftar harga resmi dan laba bisa dihitung.
- **US-2.2** Sebagai kasir, saya mau stok berkurang otomatis di setiap penjualan, supaya tidak perlu mencatat stok manual.
- **US-2.3** Sebagai pemilik, saya mau mencatat tambahan stok saat restok, supaya angka di aplikasi sama dengan stok di rak.
- **US-2.4** Sebagai pemilik, saya mau melihat daftar produk yang stoknya menipis, supaya saya tahu apa yang harus dibeli sebelum habis.

### F3. Riwayat, Void, dan PIN

- **US-3.1** Sebagai pemilik, saya mau melihat riwayat transaksi lengkap dengan item, waktu, dan status, supaya saya bisa memeriksa yang terjadi di kasir.
- **US-3.2** Sebagai pemilik, saya mau void hanya bisa dilakukan dengan PIN dan alasan, supaya tidak ada transaksi hilang diam-diam.
- **US-3.3** Sebagai pemilik, saya mau stok kembali otomatis saat void, supaya data stok tetap akurat.
- **US-3.4** Sebagai kasir, saya mau mencetak ulang struk dari riwayat, supaya pembeli yang kehilangan struk tetap terlayani.

### F4. Dashboard dan Laporan

- **US-4.1** Sebagai pemilik, saya mau melihat omzet, laba kotor, dan jumlah transaksi hari ini dalam satu layar, supaya saya tahu kondisi toko dengan cepat.
- **US-4.2** Sebagai pemilik, saya mau melihat produk terlaris pada rentang tanggal tertentu, supaya keputusan restok berdasarkan data.
- **US-4.3** Sebagai pemilik, saya mau laporan penjualan per rentang tanggal, supaya saya bisa membandingkan harian, mingguan, dan bulanan.

### F5. Backup dan Restore

- **US-5.1** Sebagai pemilik, saya mau mengekspor seluruh data toko menjadi satu file dan menyimpannya ke Drive atau WhatsApp, supaya data aman kalau HP rusak atau hilang.
- **US-5.2** Sebagai pemilik, saya mau memulihkan data dari file backup di HP baru, supaya toko bisa lanjut berjualan tanpa kehilangan riwayat.
- **US-5.3** Sebagai pemilik, saya mau diingatkan kalau backup terakhir sudah lebih dari 7 hari, supaya saya tidak lupa.

## 1.4 Di Luar Scope MVP

- Sinkronisasi cloud, multi-perangkat, multi-outlet, dan backup otomatis ke cloud
- Pembayaran non-tunai (QRIS, transfer, kartu)
- Login multi-user dan akses berjenjang penuh (MVP hanya memakai satu PIN)
- Loyalitas dan data pelanggan
- Integrasi pihak ketiga (marketplace, akuntansi, WhatsApp)
- Ekspor laporan ke Excel (diminta ditunda oleh pemilik)
- Manajemen supplier dan purchase order
- Diskon, promo, pajak, dan retur parsial
- Varian produk, modifier, dan manajemen meja (kebutuhan kafe)
- Utang/bon pelanggan
- Shift kasir dan tutup kas
- iOS dan web, cash drawer, serta fitur import CSV di dalam aplikasi

## 1.5 Metrik Keberhasilan MVP

Diukur selama pilot 14 hari di toko (minggu 7 sampai 8).

| Metrik | Target | Cara ukur |
|---|---|---|
| **Kecepatan transaksi** | Median ≤ 30 detik untuk transaksi 3 item (dari item pertama sampai selesai) | Stopwatch pada 20 transaksi nyata |
| **Adopsi** | ≥ 90% transaksi harian tercatat di Henshin selama 14 hari berturut-turut | Jumlah transaksi di aplikasi dibanding nota kertas yang tersisa |
| **Masalah harga** | Kasir bertanya harga ke pemilik ≤ 1 kali per hari di minggu ke-2 | Catatan harian kasir |
| **Akurasi stok** | Selisih stok aplikasi vs hitung fisik ≤ 5% pada 20 produk sampel | Stok opname di akhir pilot |
| **Akses informasi pemilik** | Laba dan produk terlaris hari ini terlihat dalam ≤ 10 detik dan ≤ 2 tap | Uji usability dengan pemilik |
| **Keandalan** | Crash-free sessions ≥ 99%, 0 data hilang, 100% alur F1 sampai F5 lolos uji mode pesawat | Log crash lokal dan checklist uji |
| **Struk** | ≥ 95% cetak berhasil pada percobaan pertama (minimal 50 cetakan) | Catatan uji cetak |
| **Backup** | 100% uji restore berhasil (backup, hapus data, restore, data identik); backup dilakukan ≥ 1 kali per minggu | Skenario uji dan log backup |

*Baseline kondisi manual belum ada di laporan. Sebelum rilis, ukur 10 transaksi manual sebagai pembanding metrik kecepatan.*

## 1.6 Asumsi dan Risiko Produk

- **Asumsi PIN.** PIN melindungi void, restore backup, ubah harga atau modal produk, dan layar laba. Perlu dikonfirmasi dengan pemilik.
- **Perangkat.** Emulator tidak cukup untuk menguji Bluetooth printer dan kamera barcode. Pilih printer thermal 58mm yang kompatibel ESC/POS dan uji dengan model yang benar-benar dibeli.
- **Beban input katalog.** Memasukkan seluruh produk di awal bisa memakan berjam-jam. Sisihkan waktu onboarding bersama pemilik.
- **Risiko kehilangan data.** Tanpa backup, HP rusak atau hilang berarti seluruh data toko hilang. Karena itu F5 wajib masuk MVP.

---

# Bagian 2. Arsitektur dan Tech Stack

Laporan elicitation sudah menetapkan Flutter dan SQLite. Perbandingan berikut memvalidasi pilihan tersebut dan menentukan opsi terbaik untuk satu developer dengan deadline 2 bulan. Setiap kategori dibatasi dua opsi.

## 2.1 Mobile

| Kriteria | Flutter | React Native (Expo) |
|---|---|---|
| **Kerumitan setup** | Sedang (Flutter SDK, Android Studio) | Rendah-sedang, tetapi naik begitu butuh printer Bluetooth |
| **Production-ready** | Tinggi; satu codebase, UI konsisten | Tinggi |
| **Solo dev / tim kecil** | Cocok; hot reload, satu bahasa (Dart), sudah Anda kuasai | Cocok jika kuat JS/TS, tetapi Anda belum memakainya |
| **Catatan untuk POS** | Ada plugin scan barcode dan printer ESC/POS | Printer Bluetooth butuh native module, sehingga keluar dari Expo Go |

**Keputusan: Flutter.**

## 2.2 State Management

| Kriteria | Bloc / Cubit (flutter_bloc) | Riverpod |
|---|---|---|
| **Kerumitan setup** | Rendah bagi Anda (sudah dikuasai). Cubit lebih ringan dari Bloc penuh | Rendah secara teknis, tetapi butuh mempelajari paradigma baru |
| **Production-ready** | Tinggi; struktur ketat dan mudah diuji | Tinggi; aman saat compile, cocok untuk stream database |
| **Solo dev / tim kecil** | Sangat cocok karena tanpa biaya belajar. Gunakan Cubit, bukan Bloc penuh, agar boilerplate minim | Bagus, tetapi biaya belajar tidak sepadan dengan deadline 2 bulan |

**Keputusan: Cubit (flutter_bloc).** Dependency injection cukup dengan `RepositoryProvider` bawaan, tanpa library tambahan.

## 2.3 Database Lokal

| Kriteria | Drift (di atas SQLite) | sqflite |
|---|---|---|
| **Kerumitan setup** | Sedang (butuh code generation) | Rendah |
| **Production-ready** | Tinggi; query type-safe, migrasi terstruktur, stream reaktif | Tinggi untuk stabilitas, tetapi migrasi dan mapping manual |
| **Solo dev / tim kecil** | Cocok; lebih sedikit bug SQL saat laporan makin kompleks. Ini satu-satunya hal baru yang perlu dipelajari | Cepat di awal, makin rawan error saat tabel dan join bertambah |

**Keputusan: Drift.** Alokasikan spike 2 hari di minggu 1. Jika macet, turun ke sqflite dengan interface Repository yang sama.

## 2.4 Arsitektur Kode

| Kriteria | Feature-first + Repository (layered lite) | Full Clean Architecture |
|---|---|---|
| **Kerumitan setup** | Rendah | Tinggi (entity, use case, mapper) |
| **Production-ready** | Cukup untuk MVP offline; mudah di-refactor | Tinggi; bermanfaat saat ada banyak sumber data (cloud sync) |
| **Solo dev / tim kecil** | Sangat cocok | Boilerplate tinggi dan memperlambat MVP |

**Keputusan: Feature-first + Repository.** Repository berupa interface, sehingga mengganti Drift atau menambah cloud nanti tidak menyentuh UI.

## 2.5 Struktur Proyek

```
lib/
  core/           (db, theme, utils, receipt_model)
  features/
    transaction/  (ui, cubit, repository)
    product/
    history/
    report/
    backup/
    settings/     (PIN, info toko)
  services/       (printer_service, backup_service)
```

## 2.6 Desain Data dan Aturan Production

| Tabel | Fungsi |
|---|---|
| **products** | Nama, barcode, kategori, harga jual, harga modal, stok, batas stok menipis, status aktif |
| **transactions** | Waktu, total, uang diterima, kembalian, status (selesai atau void), alasan dan waktu void |
| **transaction_items** | Item per transaksi dengan snapshot nama, harga jual, dan harga modal saat transaksi, agar laporan lama tidak berubah saat harga diganti |
| **stock_movements** | Buku besar stok (jual, restok, void, koreksi) sehingga selisih stok bisa ditelusuri |
| **settings** | Info toko (nama, alamat, pesan struk), waktu backup terakhir, versi skema. PIN disimpan sebagai hash di secure storage, bukan di database |

### Aturan production

- Uang disimpan sebagai integer rupiah, bukan double.
- Void memakai status (soft delete), bukan hapus baris.
- Penjualan dan pengurangan stok dilakukan dalam satu transaksi database (atomik).
- PIN disimpan sebagai hash di `flutter_secure_storage`.
- Setiap perubahan skema disertai migrasi yang diuji, karena data toko nyata tidak boleh rusak saat update.

## 2.7 Desain Backup dan Restore (F5)

- Ekspor memakai `VACUUM INTO` untuk snapshot yang konsisten, lalu dibagikan lewat share sheet. Pendekatan ini menghindari izin storage mentah di Android.
- Restore memakai file picker, memvalidasi file (header SQLite, tabel wajib, versi skema), dan membuat salinan pengaman sebelum menimpa data.
- Restore wajib PIN. Karena PIN tidak ikut di backup, HP baru akan diminta membuat PIN baru.
- Beri tahu pemilik bahwa file backup berisi data penjualan.

## 2.8 Desain Cetak Struk (F1 dan F3)

- Satu model `Receipt` dipakai untuk tiga keluaran: byte ESC/POS (printer), preview layar, dan PDF.
- Selama printer belum ada, pengembangan memakai preview dan PDF. Logika cetak berada di balik interface `PrinterService`.
- Lebar kertas 58mm (sekitar 32 karakter per baris).
- Android 12 ke atas butuh izin Bluetooth runtime, jadi tangani sejak awal.

---

# Bagian 3. Rencana Eksekusi

## 3.1 Timeline 8 Minggu (±200 jam)

| Minggu | Pekerjaan | Jam |
|---|---|---|
| **1** | Setup proyek, spike Drift (2 hari), skema DB, navigasi, PIN | 20 |
| **2** | F2 Produk dan Stok, scan barcode. **Printer sudah dipesan paling lambat akhir minggu ini.** | 25 |
| **3 sampai 4** | F1 keranjang, bayar, kembalian, stok atomik, lalu struk (printer harus sudah tiba di awal minggu 4) | 50 |
| **5 sampai 6** | F3 Riwayat, Void, PIN; F4 Dashboard dan Laporan; F5 Backup dan Restore | 50 |
| **7 sampai 8** | Hardening, UAT, pilot 14 hari di toko, perbaikan bug, buffer | 50 |

*Estimasi memiliki toleransi sekitar 30%. Buffer 20 jam sudah termasuk di minggu 7 sampai 8.*

## 3.2 Garis Potong Jika Waktu Molor

1. Laporan hanya preset (hari ini, 7 hari, 30 hari), tanpa pilih rentang bebas.
2. Struk sementara lewat PDF/share jika printer bermasalah.

**Tidak boleh dipotong:** stok atomik, void ber-PIN, dan backup/restore.

## 3.3 Pembagian Tugas Tim (non-coding)

| Anggota | Tugas |
|---|---|
| **Anggota 1** | Menyusun daftar produk lengkap (nama, barcode, harga jual, harga modal, stok awal) di spreadsheet sejak minggu 2. Developer cukup menulis script seed sekali pakai, tanpa fitur import di aplikasi. |
| **Anggota 2** | Wireframe layar kasir, produk, dan dashboard (Figma atau kertas) di minggu 1 sampai 2. |
| **Anggota 3** | Checklist uji dan skenario UAT, serta baseline 10 transaksi manual. |
| **Anggota 4** | Pembelian printer (58mm, ESC/POS, Bluetooth), panduan pengguna singkat, dan pelatihan pemilik serta kasir. |

## 3.4 Risiko Utama dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| **Printer atau plugin Bluetooth tidak cocok** | Pesan lebih awal, spike uji 1 hari begitu printer tiba, interface `PrinterService`, fallback PDF |
| **Belajar Drift memakan waktu** | Spike di minggu 1. Jika macet, turun ke sqflite dengan interface Repository yang sama |
| **Developer tunggal** | Buffer 20 jam dan garis potong scope |
| **Data toko hilang** | F5 wajib, pengingat 7 hari, uji restore sebelum rilis |
| **Asumsi kapasitas keliru** | Konfirmasi jam kerja nyata; jika hanya ±40 jam, kerjakan F1, F2, F5 saja |

---

# Bagian 4. Rekomendasi Final Stack

| Lapisan | Pilihan | Alasan singkat |
|---|---|---|
| **Mobile** | **Flutter** | Sesuai laporan dan keahlian Anda, satu codebase |
| **State management** | **Cubit (flutter_bloc)** | Sudah Anda kuasai, hemat waktu belajar |
| **Database lokal** | **Drift (SQLite)** | Type-safe, migrasi aman, mendukung query agregat untuk laporan |
| **Arsitektur** | **Feature-first + Repository** | Cepat dibangun dan bisa ditingkatkan tanpa tulis ulang |

**Library pendukung:** `drift`, `go_router`, `mobile_scanner`, plugin ESC/POS dan Bluetooth thermal, `pdf` dan `share_plus`, `file_picker`, `flutter_secure_storage`, `crypto` (hash PIN), `fl_chart`, `intl`. Periksa status maintenance tiap plugin di pub.dev sebelum dikunci, terutama plugin printer Bluetooth.

**Keputusan yang dapat ditinjau ulang:** Drift diganti sqflite jika spike minggu 1 gagal; cetak langsung diganti PDF/share jika plugin printer tidak cocok dengan perangkat yang dibeli.

---

# Lampiran A. Pemetaan Requirement ke Fitur MVP

| ID | Requirement (ringkas) | Fitur MVP | Status |
|---|---|---|---|
| FR-01 | Mencatat transaksi penjualan di database lokal | F1 | Masuk MVP |
| FR-02 | Total dan kembalian otomatis | F1 | Masuk MVP |
| FR-03 | Cari dan tampilkan nama serta harga produk saat transaksi | F1 | Masuk MVP |
| FR-04 | Kelola data produk | F2 | Masuk MVP |
| FR-05 | Scan barcode produk | F1 | Masuk MVP |
| FR-06 | Stok berkurang otomatis dan tampil stok terkini | F2 | Masuk MVP |
| FR-07 | Peringatan stok menipis | F2 | Masuk MVP |
| FR-08 | Riwayat transaksi beserta detail dan status | F3 | Masuk MVP |
| FR-09 | Void transaksi dengan alasan | F3 | Masuk MVP |
| FR-10 | PIN sebelum transaksi dibatalkan | F3 | Masuk MVP |
| FR-11 | Laporan penjualan per rentang tanggal | F4 | Masuk MVP |
| FR-12 | Dashboard ringkasan penjualan | F4 | Masuk MVP |
| FR-13 | Cetak dan cetak ulang struk | F1, F3 | Masuk MVP |
| FR-14 | Backup dan restore data lokal | F5 | Masuk MVP (dinaikkan karena target dipakai harian) |
| FR-15 | Ekspor laporan ke Excel | - | Di luar scope (sesuai permintaan pemilik) |
