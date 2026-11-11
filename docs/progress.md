# Progress Henshin POS

Status eksekusi `docs/implementasi.md`. Diperbarui 2026-11-12 (langkah 1–15 selesai; kategori produk; desain v2
D1–D9 — sembilan dari sembilan, selesai).

Keputusan arsitektur yang diambil selama eksekusi dicatat terpisah di
`docs/keputusan-arsitektur.md`.

## Ringkasan

| Langkah | Isi | Status |
|---|---|---|
| 1 | Kunci DI + wiring database | ✅ selesai |
| 2 | Migrasi DB + seed kategori awal | ✅ selesai |
| 3 | Settings + PIN (hash, bukan plaintext) | ✅ selesai |
| 4 | CRUD produk + validasi harga/stok | ✅ selesai |
| 5 | Restok + ledger `stock_movements` + peringatan stok menipis | ✅ selesai |
| 6 | Keranjang + bayar + kembalian + simpan atomik | ✅ selesai |
| 7 | Scan barcode kamera + fallback | ✅ selesai, terverifikasi di HP saat langkah 15 |
| 8 | Model `Receipt` + preview + PDF/share | ✅ selesai |
| 9 | Cetak ESC/POS Bluetooth | 🟡 **sebagian**: `PrinterService` + impl PDF selesai; impl Bluetooth ditunda sampai printer tiba |
| 10 | Riwayat + detail + cetak ulang | ✅ selesai |
| 11 | Void ber-PIN + alasan + stok kembali | ✅ selesai |
| 12 | Dashboard hari ini + laporan preset + produk terlaris | ✅ selesai |
| 13 | Export backup (`VACUUM INTO`) + share + pengingat 7 hari | ✅ selesai |
| 14 | Restore: picker + validasi + salinan pengaman + PIN | ✅ selesai |
| 15 | Mode pesawat end-to-end + pilot checklist | ✅ selesai, kecuali jalur cetak thermal (langkah 9) |

Fondasi (1–3), F2 Produk & Stok (4–5), dan F1 Kasir + scan + struk (6–8)
selesai di sisi kode. Langkah 9 sengaja berhenti di interface + fallback PDF
sesuai PRD §2.8 ("selama printer belum ada, pengembangan memakai preview dan
PDF"); impl ESC/POS menunggu printer fisik + spike 1 hari (PRD §3.4).
F3 Riwayat & Void (10–11), F4 Dashboard & Laporan (12), dan F5 Backup &
Restore (13–14) selesai. Backup sekarang terbukti bisa dipulihkan — tes
`backup → hapus → restore → identik` jalan di suite, jadi safety net data
PRD §1.6 berdiri utuh, bukan separuh seperti setelah langkah 13.

**Kelima belas langkah `docs/implementasi.md` sudah dijalankan.** Langkah 15
menutupnya: F1→F5 diuji pemilik dalam mode pesawat di HP, median transaksi
3 item ≤30 detik sesuai PRD §1.5, dan scan barcode akhirnya terbukti jalan di
perangkat nyata. Yang tersisa bukan langkah rencana, tapi tiga hal yang sudah
dicatat sebagai utang: impl cetak ESC/POS yang menunggu printer fisik
(langkah 9) dan dua metrik PRD yang belum bisa diukur — lihat tabel utang
teknis. `docs/implementasi_design.md` juga sudah tuntas: **D1–D9, sembilan
dari sembilan**, jadi seluruh aplikasi sekarang berdiri di desain v2 dan tidak
ada lagi layar yang tertinggal di v1. Dua dokumen rencana itu kini keduanya
habis; pekerjaan berikutnya belum punya rencana tertulis.

Sejak D2 isi `docs/implementasi.md` sudah tidak menggambarkan susunan layar
aplikasi: Dasbor (langkah 12) dibuang dan Kasir (langkah 6) pindah jadi tab
pertama. Sejak D7 alur void (langkah 11) juga berbeda dari yang ditulis di
sana: PIN dan alasan sekarang satu sheet, bukan dua langkah berurutan. Dan
sejak D8 laporan langkah 12 berubah dua kali: presetnya `Hari ini / 7 hari /
Bulan ini` (bukan 30 hari bergulir, ADR-056) dan **laba kotor sekarang
ber-PIN** (ADR-057) — angka yang di langkah 12 terbuka begitu layar dibuka.

**Verifikasi saat ini:** 210 tes lolos, `flutter analyze` bersih. Sejak D9
`flutter test` tanpa argumen akhirnya jalan — template counter bawaan yang
membuatnya gagal sejak awal proyek sudah dihapus.

Uji manual di device oleh pemilik repo: langkah 1–5, 7, dan 10–15 ✅; langkah 6
(kasir) dan 8 (struk) sebagian — lima bug ditemukan dan sudah diperbaiki, lihat
"Perbaikan setelah verifikasi manual". Langkah 13 sekaligus membuktikan
`SharePlus.instance.share` memang jalan di Android, yang sebelumnya belum pernah
terkonfirmasi; langkah 14 menambah `file_picker` ke daftar yang sudah
terbukti di HP — sementara `SystemNavigator.pop()` justru terbukti **tidak**
cukup, lihat "Perbaikan setelah verifikasi manual". Langkah 15 menutup lubang
terlama: **scanner barcode akhirnya jalan di HP fisik**, yang sejak langkah 7
hanya pernah diuji di emulator.

Desain v2 diverifikasi pemilik per kelompok langkah: D1 (2026-11-09), D2–D5
(2026-11-10), D6–D7 (2026-11-12), D8–D9 (2026-11-12). Dua bug ditemukan
pemilik di HP dan tidak akan pernah ditemukan suite: PayBar yang menelan
seluruh layar (ADR-051) dan assert `!_debugLocked` saat men-scan barcode
terdaftar dari layar Produk (ADR-055). Yang kedua menegaskan batas yang sudah
dicatat: bug di dalam layar scanner tidak bisa dijaga tes karena controller
kameranya butuh platform channel yang tidak ada di `flutter test`.

Arah sebaliknya terbukti di D8: crash layout yang **tertangkap suite lebih
dulu**. `CrossAxisAlignment.stretch` di dalam `ListView` membuat Laporan versi
pertama D8 crash begitu dibuka, dan tes widget baru itulah yang menemukannya
sebelum APK-nya sampai ke HP (ADR-058). Dua ADR yang berdampingan ini yang
menandai batasnya: geometri bisa diuji, kamera tidak.

**Masih belum pernah diuji di HP:** cetak ESC/POS ke printer thermal (belum ada
implementasinya, dan printernya belum ada — langkah 9), dan jalur share khusus
PDF struk dengan mime `application/pdf` (`SharePlus.instance.share` sendiri
sudah terbukti lewat backup langkah 13, jadi yang tersisa hanya mime-nya).

---

## Langkah 1 — Kunci DI + wiring database

- `lib/injection_container.dart`: `sl = GetIt.instance` + `initDependencies()`.
- Koneksi DB dibuka di `injection_container.dart`, bukan di `app_database.dart`,
  memakai `driftDatabase(name: 'henshin')` dengan `databaseDirectory:
  getApplicationSupportDirectory`.
- `main.dart`: `initDependencies()` sebelum `runApp`, lalu `MultiBlocProvider`
  dengan `BlocProvider<ProductBloc>`.
- Hanya dependency yang benar-benar dikonsumsi yang didaftarkan.

## Langkah 2 — Migrasi DB + seed

- `schemaVersion` 1 → 2. `products` dapat `costPrice`, `lowStockThreshold`,
  `isActive`; tabel `settings` baru (satu baris, typed).
- Migrasi memakai tooling resmi Drift: `build.yaml`, `drift_schemas/`,
  `lib/core/database/app_database.steps.dart`, `stepByStep(from1To2:)`.
- Seed di `beforeOpen` ketika tabel kosong: kategori default `'Umum'`
  (`kDefaultCategoryName`) + satu baris `settings`.
- Tes: `SchemaVerifier` v1→v2 + integritas data dengan data dummy + 4 tes seed.

## Langkah 3 — Settings + PIN

- `features/setting/`: `PinRepository` (interface) + `PinRepositoryImpl` +
  3 usecase (`HasPin`, `SetPin`, `VerifyPin`) + `PinBloc`.
- PIN 6 digit, di-hash PBKDF2-HMAC-SHA256 100.000 iterasi dengan salt acak,
  disimpan **hanya** di `flutter_secure_storage` — tidak pernah di DB.
- Jeda bertingkat setelah 4 percobaan bebas: 5s → 30s → 5 menit.
- Layar: `PinCreateScreen` (isi lalu ulangi), `PinVerifyScreen`, `PinGate`.
- Entry point: bagian **Keamanan** di layar Pengaturan. Ganti PIN wajib
  verifikasi PIN lama.
- Tes: 13 unit + 2 widget, termasuk "PIN tidak ada di database sama sekali"
  (menyapu seluruh `db.allTables`).

## Langkah 4 — CRUD produk + validasi

- `schemaVersion` 2 → 3: unique index `products_barcode_unique` pada `barcode`.
- `ProductEntity`/`NewProduct` diperluas ke kolom langkah 2; `isLowStock`
  memakai batas per produk.
- Validasi di repository: nama wajib, harga/modal/stok/batas tidak boleh
  negatif, nama & barcode di-trim, barcode kosong → NULL.
- `product_form_screen.dart` dibangun dari nol (sebelumnya 0 byte);
  `product_list_screen.dart` diganti dari data dummy ke `ProductBloc`.
- `PinGate` dipasang: ubah harga jual/modal produk existing wajib PIN.
- `core/utils/currency_formatter.dart` dibuat (`formatRupiah`, `parseRupiah`).
- **Bug diperbaiki:** foreign key SQLite tidak pernah ditegakkan — semua
  `references` tidak berfungsi. Lihat ADR-008.

## Langkah 5 — Restok + ledger + peringatan stok menipis

- `ProductDao.restock()` dan `adjustStock()` menulis 1 baris
  `stock_movements` dalam satu transaksi Drift. Stok awal produk baru juga
  dicatat sebagai baris `'in'`.
- `updateProduct` tidak lagi menyentuh kolom `stock` — satu-satunya jalan
  mengubah stok adalah restok/koreksi, jadi ledger tidak bisa bolong.
- `watchLowStockProducts()` tanpa argumen, membandingkan
  `stock <= lowStockThreshold` di SQL, hanya produk aktif.
- UI: `StockSheet` (bottom sheet, mode restok/koreksi), banner "N produk perlu
  restok" di layar Produk, dan `LowStockScreen` di rute `/perlu-restok`.
- **Bug diperbaiki:** produk sempat tidak bisa dihapus sama sekali setelah stok
  awal ikut dicatat. Lihat ADR-011.

## Langkah 6 — Keranjang + bayar + simpan atomik

- `schemaVersion` 3 → 4: `transaction_items` dapat `productName` +
  `costPriceAtSale` (PRD §2.6). Tanpa ini laba kotor di langkah 12 tidak bisa
  dihitung dari snapshot.
- `TransactionDao.createSale()` menulis header + item + pengurangan stok +
  ledger dalam **satu** transaksi Drift. Total dihitung ulang dari harga di DB,
  bukan dari angka yang dikirim UI. Stok kurang → exception → seluruhnya
  di-rollback.
- `TransactionRepository` (file tadinya 0 byte) + `CreateSale` + `CartBloc`
  (keranjang in-memory, total/kembalian otomatis, keranjang hanya direset
  setelah DB benar-benar menyimpan).
- `CashierScreen` baru di rute `/mulai-transaksi`; scanner lama di-rename jadi
  `barcode_scanner_screen.dart` (rute `/scan` sempat dibuat di sini lalu
  dihapus di langkah 7 — lihat ADR-017).
- 18 tes: transaksi 3 item (total/kembalian/stok/snapshot/ledger), snapshot
  tidak berubah saat harga produk diubah, keatoman saat stok kurang, dan data
  tetap ada setelah DB ditutup lalu dibuka lagi.
- `AppDatabase` di DI sekarang punya `dispose` sehingga `sl.reset()` menutup
  file DB-nya.

## Langkah 7 — Scan barcode kamera

- Scanner ditulis ulang mengikuti pola `mobile_scanner` v7: `autoStart: false`
  + `controller.start()` eksplisit, langganan `controller.barcodes`,
  `didChangeAppLifecycleState` dijaga `hasCameraPermission`, dan
  `dispose()` async.
- **Scan berturut**: kamera tetap hidup, tiap barcode dikenali langsung masuk
  keranjang dengan notifikasi "Nama +1 · N item" dan haptic. Tombol
  "Selesai · N item" kembali ke kasir.
- Barcode yang sama diterima lagi setelah jeda 1,5 detik — bukan diblokir
  permanen, karena kasir sering men-scan beberapa barang identik.
- Barcode tidak dikenal → sheet dengan tiga pilihan: tambah produk (barcode
  sudah terisi di form), cari manual, atau lanjut scan.
- Izin kamera ditolak → tombol "Buka Pengaturan" (`openAppSettings`), supaya
  kasir tidak mentok di layar hitam.
- Tombol/ikon Scan ditambahkan di layar kasir. Scanner di-push dengan
  `BlocProvider.value`, bukan rute sendiri (lihat ADR-017).

## Langkah 8 — Model `Receipt` + preview + PDF/share

- `Receipt` + `ReceiptLine` (entity) dan `ReceiptFormatter` yang merender
  baris teks selebar 32 karakter (58mm, PRD §2.8). **Formatter ini satu-satunya
  tempat tata letak struk ditentukan** — preview, PDF, dan nanti ESC/POS
  memakai keluaran yang sama, jadi struk di layar tidak bisa beda dengan yang
  tercetak.
- `TransactionRepository.buildReceipt()` menyusun struk dari transaksi
  tersimpan, memakai snapshot `transaction_items` — cetak ulang struk lama
  tetap sama walau harga produk berubah (US-3.4).
- `ReceiptPreviewScreen`: menampilkan baris struk apa adanya dengan font
  monospace, plus tombol bagikan dan salin teks. Dibuka otomatis setelah bayar.
- **Info toko disambungkan**: `SettingsDao` + `SettingsRepository` +
  `StoreInfo` + `StoreInfoScreen`. Tabel `settings` dari langkah 2 berhenti
  jadi tabel mati, dan baris dummy "Nama toko: Henshin Store" di Pengaturan
  diganti data sungguhan.
- 23 tes: lebar baris tidak pernah lewat 32 karakter (termasuk kata yang lebih
  panjang dari kertas), angka rata kanan tidak pernah terpotong, penanda VOID
  dan CETAK ULANG, struk dari transaksi nyata, PDF benar-benar terbentuk
  (header `%PDF-`), nama produk non-Latin1 tidak menggagalkan PDF, dan info
  toko tersimpan/terbaca.

## Langkah 9 — Cetak ESC/POS (sebagian)

- `PrinterService` (interface) + `PdfPrinterService` (impl PDF/share dengan
  `PdfPageFormat.roll57` dan font Courier bawaan — tanpa aset font).
- `PrintFailure` ditambahkan: gagal cetak **tidak pernah** berarti transaksi
  gagal, karena penjualan selalu tersimpan lebih dulu (US-1.4).
- **Impl Bluetooth belum dibuat.** Plugin yang dikunci untuk nanti:
  `print_bluetooth_thermal` + `esc_pos_utils_plus`. `esc_pos_bluetooth` yang
  disebut rencana **ditolak** karena rilis terakhirnya 2021-10-06. Lihat
  ADR-023.

## Langkah 10 — Riwayat + detail + cetak ulang

- `TransactionDao.watchHistory({since})`: satu query join + `groupBy` +
  `qty.sum()` dengan `useColumns: false`, jadi jumlah item per transaksi ikut
  tanpa N query tambahan. Urutan `date DESC, id DESC` — lihat ADR-030.
- `TransactionSummary` (entity) hanya memuat yang terlihat di list; detailnya
  dibaca ulang sebagai `Receipt`, jadi angka struk tidak digandakan.
- `transaction_history_screen.dart` diganti dari 4 baris dummy ke stream nyata.
  Tab Hari ini/7/30 hari hanya menggeser `since`; "hari ini" = tengah malam
  lokal, bukan 24 jam ke belakang. Transaksi void **ikut** tampil (jejak audit).
- `TransactionDetailScreen` baru: item dengan harga snapshot, total/bayar/
  kembali, tombol **Cetak ulang** (membuka `ReceiptPreviewScreen(isReprint:
  true)` — nol kode cetak baru) dan **Void**.
- Pola state: `StreamBuilder` + repository, bukan Bloc baru. Ditanyakan dan
  dipilih pemilik repo — lihat ADR-028.

## Langkah 11 — Void ber-PIN + alasan + stok kembali

- `TransactionRepository.voidTransaction(id, reason)`; DAO-nya sudah ada sejak
  langkah 6 dan sekarang **menolak transaksi yang sudah void** — tanpa itu stok
  kembali dua kali. Lihat ADR-029.
- Alur UI: `PinGate.require` dulu, **baru** dialog alasan, supaya yang tidak
  berhak tidak sempat mengetik apa pun. Tombol Void mati selama alasan kosong,
  dan repository tetap menolak alasan yang hanya spasi.
- Soft delete dijaga: baris `transactions`/`transaction_items` tidak pernah
  dihapus, stok dikembalikan + satu baris `stock_movements` bertipe `in`, semua
  dalam satu transaksi Drift.
- Tes: 8 tes repository baru — urutan + jumlah item, filter `since`, void muncul
  di riwayat, status/stok/ledger setelah void, baris tidak terhapus, alasan
  kosong ditolak tanpa mengubah stok, void dua kali ditolak, transaksi tidak ada
  ditolak.

## Langkah 12 — Dashboard + laporan preset + produk terlaris

- `ReportDao` dirapikan: `getTotalSales` dan `getTransactionCount` yang
  menganggur **dihapus**; omzet dan jumlah transaksi dihitung dari header yang
  memang sudah diambil untuk grafik harian. Yang baru: `getProfitAndItemCount`
  (satu agregat `SUM((priceAtSale − costPriceAtSale) * qty)`) dan
  `getBestSellers` ditulis ulang agar mengembalikan `(nama, qty)`, bukan
  `TypedResult` yang membocorkan tipe Drift ke layer atas.
- `SalesReport` + `ReportPeriod` (preset Hari ini/7/30 hari, rentang bebas
  sengaja tidak ada — garis potong PRD §3.2). `rangeFrom` memakai tengah malam
  **lokal**, bukan 24 jam ke belakang.
- Transaksi void dikecualikan dari omzet, laba, jumlah transaksi, item terjual,
  dan produk terlaris. Laba selalu dari snapshot item.
- Pengelompokan omzet per hari dihitung di Dart, bukan `strftime` — lihat
  ADR-032. Hari tanpa penjualan tetap ada dengan nilai 0.
- Dashboard dari data nyata + `RefreshIndicator` + muat ulang saat kasir
  ditutup (dashboard hidup di `IndexedStack`, tidak menyegarkan dirinya
  sendiri). Badge persentase jadi perbandingan nyata vs kemarin dan
  **hilang** kalau kemarin nol.
- `ReportScreen` baru di rute `/laporan`, masuk dari tombol di kanan atas
  dashboard. Kotak angka dan list terlaris dipakai bersama dashboard lewat
  `report_stats.dart`.
- Grafik omzet 7 hari memakai `fl_chart` (`BarChart` + tooltip per hari);
  `fl_chart ^1.3.0` sudah ada di `pubspec.yaml`, pure Dart, tanpa sisi native.
  Lihat ADR-033.
- Laba kotor tampil **terbuka tanpa PIN** — asumsi PRD §1.6 dibatalkan atas
  keputusan pemilik repo. Lihat ADR-031.
- Tes: 13 tes repository — rentang tiap preset, angka vs hitungan manual, void
  dikecualikan, luar periode, laba dari snapshot setelah harga diubah, urutan
  terlaris, produk terhapus tetap muncul, hari kosong = 0, dan penjualan jam 1
  pagi tetap masuk hari itu (regresi zona waktu).

## Langkah 13 — Export backup + share + pengingat 7 hari

- `AppDatabase.exportInto(File)`: `VACUUM INTO ?` lewat `customStatement`,
  resep resmi Drift. Hasilnya salinan yang sudah di-checkpoint — tidak pernah
  berisi transaksi setengah jalan, beda dari menyalin `.sqlite` mentah yang
  bisa tertinggal WAL-nya. Tidak boleh dipanggil dari dalam `transaction()`.
- `BackupRepository` + `BackupRepositoryImpl`: `exportToFile()` (snapshot saja,
  bisa diuji tanpa UI) dipisah dari `exportAndShare()` (share sheet + catat
  `lastBackupAt`). Direktori output, fungsi share, dan jam disuntikkan.
- File ditulis ke **cache aplikasi**, bukan folder publik: sejak Android 11
  menulis ke penyimpanan bersama butuh SAF/MediaStore, dan share sheet sudah
  menjangkau Drive/WA seperti yang diminta PRD §1.6. Lihat ADR-034.
- Dibagikan dengan `mimeType: 'application/octet-stream'` — `.sqlite` tidak
  punya mime terdaftar di Android dan tanpa itu sebagian target share menolak
  atau menyembunyikan file. Nama file memuat tanggal **dan jam** supaya dua
  backup di hari yang sama tidak saling menimpa di folder tujuan.
- `lastBackupAt` hanya dicatat kalau share sheet tidak dibatalkan; status
  `unavailable` (umum di Android) tetap dihitung berhasil. Lihat ADR-035.
- `StoreInfo.backupIsStale(now)` + `daysSinceBackup(now)`: ambang dihitung per
  **hari kalender**, bukan per 168 jam, mengikuti ADR-032. Belum pernah backup
  juga dianggap basi. Lihat ADR-036.
- UI: banner merah `BackupReminder` di atas dashboard dengan tombol "Backup
  sekarang", dan baris "Backup data" di Pengaturan dengan badge "Perlu backup".
  Keduanya memanggil satu helper `BackupAction.run` — pola `PinGate.require`,
  bukan bloc baru (ADR-028).
- Dua baris dummy di grup "Data lokal" dihapus: switch "Backup otomatis"
  (menjanjikan fitur yang tidak ada) dan "Export laporan CSV" (out-of-scope,
  AGENTS.md §6).
- Tes: 14 tes baru — header SQLite file hasil export, isi identik dengan data
  asli, perubahan setelah snapshot tidak ikut, export ulang di jam sama
  menimpa alih-alih gagal, empat jalur `lastBackupAt`, empat kasus ambang hari.
  `ReportRepository` dan `BackupRepository` ditambahkan ke
  `test/injection_container_test.dart` (`ReportRepository` dari langkah 12
  ternyata belum pernah masuk situ).
- Dua cacat ditemukan sendiri saat menulis, bukan dari verifikasi: tombol back
  bisa menutup dialog tunggu lalu `pop()` menutup halaman di belakangnya
  (dikunci `PopScope`), dan ekspektasi tes header SQLite salah — 16 byte-nya
  berakhir NUL dan `trimRight()` tidak membuangnya.

## Langkah 14 — Restore: picker + validasi + salinan pengaman + PIN

- `BackupRepositoryImpl.validate(File)`: publik dan statis supaya tiap
  aturannya bisa diuji tanpa menyentuh database aktif. Urutannya dari yang
  paling murah ke paling mahal — file ada → panjangnya cukup → 16 byte header
  `SQLite format 3 + NUL` → dibuka read-only → enam tabel wajib ada →
  `PRAGMA user_version` masuk rentang.
- File kandidat **tidak pernah dibuka sebagai `AppDatabase`**: membukanya
  berarti menjalankan `onUpgrade` dan mengubah backup milik pemilik. Karena itu
  `package:sqlite3` dipakai langsung (dinaikkan dari dependensi transitif ke
  langsung, tanpa unduhan baru) dengan `OpenMode.readOnly` — kalau file-nya
  rusak, sqlite tidak boleh "memperbaikinya" di tempat.
- Versi skema dibaca dari `PRAGMA user_version`, **bukan** kolom
  `settings.schemaVersion`: kolom itu hanya diisi saat seed dan sudah ditandai
  basi di kodenya sendiri, sedangkan `user_version` selalu dinaikkan Drift.
  Skema 1–4 diterima dan dinaikkan migrasi saat dibuka ulang; skema 5+ ditolak
  karena menurunkan versi tidak mungkin. Lihat ADR-041.
- Penukaran filenya berurutan supaya tidak ada keadaan setengah jalan: salinan
  pengaman lewat `exportInto` (`VACUUM INTO`, jadi konsisten) **selagi koneksi
  masih hidup** → backup disalin ke `henshin.sqlite.restore` di sebelah file
  aktif → koneksi ditutup → `rename` yang atomik di filesystem yang sama.
  Menyalin langsung ke atas file aktif akan meninggalkan database separuh
  tertimpa kalau prosesnya mati di tengah.
- Sidecar `-wal` dan `-shm` milik database lama dibuang setelah penukaran:
  kalau ditinggal, sqlite bisa memutar ulang transaksi lama di atas data yang
  baru dipulihkan.
- Kalau `rename` gagal setelah koneksi ditutup, pesannya menyebut keadaan
  sebenarnya — "data lama masih utuh, tutup dan buka lagi Henshin" — bukan
  sekadar "gagal", karena di titik itu datanya aman tapi aplikasinya tidak
  bisa dipakai.
- `RestoreAction` (presentation): PIN lewat `PinGate` → picker → validasi →
  konfirmasi merah paling akhir. Urutan itu disengaja supaya pemilik tidak
  pernah diminta menyetujui penimpaan data sebelum file-nya terbukti sah.
- `FileType.any` tanpa `allowedExtensions`: filter ekstensi di Android
  dikerjakan file explorer bawaan HP dan sering diabaikan, jadi validasi
  dilakukan sendiri — yang memang diminta rencana.
- File dari picker selalu disalin dulu ke cache lewat `readAsByteStream()`:
  file dari Drive datang sebagai `content://` tanpa jalur disk (`path` null di
  `file_picker` 13), dan sqlite butuh jalur nyata. Satu jalur kode untuk semua
  sumber, bukan dua cabang.
- Selesai restore, aplikasi **ditutup** lewat dialog yang tidak bisa dilewati.
  Harus `exit(0)`, bukan `SystemNavigator.pop()` — lihat bug di bawah. Rebuild
  in-process (`sl.reset()` + remount) sengaja ditolak. Lihat ADR-039.
- 13 tes baru (total 142 → 155), termasuk metrik PRD langkah 14:
  `backup → hapus produk → restore → nama/stok/harga identik`. Database tes
  harus berupa file nyata, bukan `NativeDatabase.memory()`, karena yang diuji
  justru close + rename.
- Satu tes menjaga hal yang paling mudah rusak diam-diam: file tidak sah harus
  gagal **tanpa menutup koneksi** dan tanpa mengubah ukuran file aktif.

## Langkah 15 — Mode pesawat end-to-end + pilot checklist

Langkah tanpa koding: tidak ada baris kode yang berubah dan tidak ada tes baru
(tetap 155). Isinya pengukuran, dan yang tercatat di bawah adalah yang
dilaporkan pemilik repo setelah menjalankannya di HP sendiri.

**Yang lolos.**

- F1→F5 dijalankan penuh dalam mode pesawat. Tidak ada jalur yang menunggu
  jaringan — memang tidak boleh ada: aplikasi ini tidak punya backend sama
  sekali (AGENTS.md §1).
- Median menyelesaikan transaksi 3 item **≤30 detik**; metrik PRD §1.5
  tercapai.
- Baseline 10 transaksi manual dijalankan sebagai pembanding.
- **Scan barcode terbukti jalan di HP fisik.** Catatan penting yang baru
  diketahui sesudahnya: yang terbukti di uji ini hanya bahwa **kamera membaca
  barcode**, bukan bahwa produk terdaftar ketemu — pencarian produknya ternyata
  rusak sejak lama dan baru ditemukan 2026-11-08. Lihat "Perbaikan setelah
  verifikasi manual". Ini lubang terlama di proyek:
  sejak langkah 7 scanner hanya pernah dijalankan di emulator, dan PRD §1.6
  sendiri menyebut emulator tidak cukup. Baris utang tekniknya dihapus.

**Yang tidak tercakup, dan tetap tidak tercakup.**

- Cetak ESC/POS ke printer thermal sengaja di luar uji: implementasinya belum
  ada dan printernya belum tiba (langkah 9 masih sebagian). Metrik PRD
  "50× cetak ≥95% sukses" belum terukur, dan tidak akan terukur sampai
  hardware-nya ada.
- Skenario UAT tertulis tidak dibuat; pengujiannya manual tanpa artefak. Uji
  berikutnya setelah perubahan besar — misalnya desain UI v2 — jadi tidak
  punya pembanding yang bisa diulang. Dicatat sebagai utang.
- Angka crash-free ≥99% tidak diukur. Tidak ada crash yang dilaporkan selama
  pengujian, tapi "tidak terlihat crash" bukan sebuah rate: menghitungnya
  butuh telemetri yang tidak ada dan tidak boleh ada di aplikasi offline ini.
  Lihat ADR-042.

## Perbaikan setelah verifikasi manual

- **Produk nonaktif gagal dihapus, dan pesannya menyuruh menonaktifkannya
  lagi** (dilaporkan pemilik 2026-11-08, diverifikasi hari yang sama).
  Penolakannya ternyata **benar** — jalur hapus tidak pernah membaca
  `isActive`; yang mengunci produk adalah baris `transaction_items`, yaitu
  riwayat penjualannya. Dibuktikan dengan empat skenario di DB asli sebelum
  satu baris pun diubah: nonaktif + pernah terjual ❌, nonaktif belum pernah
  terjual ✅, nonaktif + pernah direstok ✅, dan terjual lalu **di-void** ❌.
  Yang rusak pesannya: ia menyarankan tindakan yang sudah dilakukan pemilik,
  jadi terbaca seolah aplikasi mengira produknya masih aktif. Sekarang pesannya
  menyebut nama produk, alasannya, dan hanya menyarankan "nonaktifkan" kalau
  produk itu memang masih aktif. Sekalian ditemukan cacat kedua di tempat yang
  sama: blok `catch`-nya melabeli **setiap** exception sebagai "sudah dipakai di
  transaksi", jadi error apa pun akan menyamar jadi pesan yang masuk akal dan
  tidak pernah terlihat — kelas bug yang sama dengan `Left` yang tertelan di
  ADR-044, dan kedua kalinya di repo ini. 3 tes baru (170 → 173). Lihat
  ADR-045.

- **Produk yang barcodenya sudah terdaftar tidak ketemu saat di-scan**
  (dilaporkan pemilik 2026-11-08). Kameranya membaca barcode dengan benar —
  sheet "Barcode belum terdaftar" muncul, artinya dekodenya sehat — tapi
  pencarian produknya gagal. Penyebabnya jalur tulis dan jalur baca tidak
  sepakat soal apa kuncinya: `addProduct`/`updateProduct` memangkas barcode
  lewat `_blankToNull`, sementara `getProductByBarcode` memakai kode dari
  scanner apa adanya, dan DAO-nya mencocokkan **persis**
  (`barcode.equals`). Beberapa simbologi 1D (Code 39) juga mengembalikan
  `rawValue` dengan karakter penutup. Diperbaiki dengan memangkas di jalur
  baca juga, plus menolak kode kosong supaya tidak pernah mencocoki produk
  tanpa barcode. 3 tes baru (155 → 158). Lihat ADR-044.

  Ikut ditemukan saat menelusuri: `_onDetect` melipat `Left(DatabaseFailure)`
  dan `Right(null)` menjadi satu hasil lewat `getOrElse(() => null)`, jadi
  **setiap** error database muncul sebagai "Barcode belum terdaftar". Itu yang
  membuat bug ini sulit dilihat dari layar. Sekarang error memunculkan snackbar
  merah berisi pesannya, dan produk nonaktif dibedakan dengan pesannya sendiri
  — sebelumnya produk nonaktif juga disebut "belum terdaftar", padahal
  mendaftarkannya lagi justru ditolak index unik barcode.

  **Perbedaan karakter yang sebenarnya tidak pernah tercatat.** Perbaikannya
  terbukti bekerja di HP pemilik, tapi dua string yang dibandingkan — kode
  yang terbaca scanner dan nilai yang tersimpan — tidak pernah diambil, jadi
  tidak ada bukti karakter mana yang berbeda. Kalau gejala serupa muncul lagi,
  jangan anggap kasus ini sudah menjelaskannya.

  Satu dugaan yang diperiksa dan **salah**: barcode kembar. Index uniknya
  dideklarasikan dengan `@TableIndex`, jadi `createAll()` ikut membuatnya di
  install baru — bukan hanya lewat migrasi 2→3 — sehingga duplikat tidak
  mungkin ada dan `getSingleOrNull()` tidak pernah bisa melempar karenanya.

- **Halaman scan diubah ke potrait** (permintaan pemilik 2026-11-02,
  dikerjakan 2026-11-08). Kunci landscape di `initState` diganti
  `DeviceOrientation.portraitUp`; frame pemandu diubah jadi lebar-dan-pendek
  (0,85 × lebar layar, tinggi 0,55 × lebar frame) karena rumus lama
  menghasilkan kotak menjulang tinggi di potrait — bentuk paling sulit untuk
  barcode 1D. Teks instruksi dipindah ke bawah frame; dulu dipaku `bottom: 24`
  dan bertumpuk dengan tombol "Selesai · N item". `dispose` sekarang membuang
  preferensi orientasi (`const []`) alih-alih mengunci potrait — cacat lama
  yang membuat **seluruh** aplikasi terkunci potrait setelah scanner dibuka
  sekali, tidak pernah terlihat karena aplikasinya memang dipakai potrait.
  `scanWindow` sengaja tidak dipakai. Lihat ADR-043.

- **Layar putih kosong saat aplikasi dibuka lagi setelah restore**
  (dilaporkan pemilik, langkah 14). `SystemNavigator.pop()` berhasil menutup
  aplikasi, tapi ia hanya menutup Activity dan membiarkan prosesnya hidup —
  jadi saat dibuka lagi `main()` tidak jalan ulang, `initDependencies()` tidak
  jalan ulang, dan get_it masih memegang `AppDatabase` yang baru ditutup oleh
  restore. Diganti `exit(0)`. Diagnosis dipisahkan satu gerakan: membuang
  aplikasi dari Recents lalu membukanya kembali menampilkan data yang sudah
  dipulihkan dengan benar, yang membuktikan file databasenya sehat dan
  masalahnya murni daur hidup proses. **Tidak ada tes Dart yang bisa
  menangkap ini** — tes selalu berjalan di proses baru. Lihat ADR-039 dan
  ADR-025.

- **Form tambah produk tidak pernah tertutup setelah simpan sukses** (dilaporkan
  pemilik). `ProductState.writeCount` ditambahkan sebagai penanda selesainya
  operasi tulis; `status` saja tidak cukup. Lihat ADR-013.
- **"Bagikan PDF" gagal di HP — dua penyebab terpisah** (dilaporkan pemilik).
  (1) File ditulis ke `Directory.systemTemp`, yang di Android menunjuk `/tmp`
  dan tidak bisa ditulis aplikasi; diganti `getTemporaryDirectory()`. Tes
  desktop lolos sepanjang waktu karena `systemTemp` valid di Windows —
  ADR-026. (2) Lalu muncul `MissingPluginException` pada channel
  `dev.fluttercommunity.plus/share`: **bukan** bug `share_plus` dan bukan
  kode Dart (API v13-nya sudah benar), tapi APK di device dibuild 18:19
  sementara `share_plus` baru masuk `pubspec.yaml` 21:22 — sisi native-nya
  belum ada di binary. Butuh `flutter run` penuh. Kegagalan cetak sekarang
  ikut di-`debugPrint` supaya bisa diambil lewat adb, tidak hanya muncul di
  snackbar.
- **`StoreInfoScreen` macet di spinner selamanya** (dilaporkan pemilik).
  Pemuatan async di `initState` tidak ber-try/catch, jadi satu exception
  membuat flag loading tidak pernah dimatikan — tanpa pesan, tanpa jalan
  keluar. Diperbaiki di tiga layar yang berpola sama. Lihat ADR-025.
- **Struk tidak menutup dirinya setelah dibagikan** (dilaporkan pemilik).
  `ReceiptPreviewScreen` sekarang `pop()` setelah cetak/bagikan sukses, dan
  tetap terbuka kalau gagal supaya bisa dicoba lagi. Catatan: di Android
  `share_plus` tidak bisa diandalkan membedakan "dibagikan" dari "share sheet
  ditutup", jadi membatalkan sheet juga menutup layar ini.
- **Layar kasir tidak punya tombol keluar** (dilaporkan pemilik). Dashboard
  membukanya dengan `context.go` yang mengganti stack navigasi, jadi AppBar
  tidak memunculkan tombol kembali **dan** tombol back fisik keluar dari
  aplikasi. Diganti `context.push` + tombol kembali eksplisit + konfirmasi
  kalau keranjang masih terisi. Lihat ADR-020.

---

## Kategori produk (di luar langkah rencana)

Dikerjakan 2026-11-08 atas permintaan pemilik, diverifikasi pemilik hari yang
sama. Desainnya sudah dikunci di sesi grilling 2026-11-02 dan tersimpan di
`.scratch/kategori-produk/issues/01-buat-kategori-dari-form-produk.md`; yang
dikerjakan di sini persis itu. Alasan lengkap tiap keputusan ada di **ADR-038**.

**Lubang yang ditutup.** Tab kategori di daftar produk hanya pernah berisi
"Semua" dan "Umum" hasil seed langkah 2, dan **tidak ada apa pun di aplikasi
yang bisa membuat kategori** — `CategoryDao.addCategory` ada sejak langkah 2 dan
tidak pernah dipanggil dari mana pun. Ini lubang di rencana, bukan bug:
PRD §F2 menyebut kategori sebagai *kolom produk*, bukan entitas yang dikelola,
jadi tidak ada langkah yang pernah menugaskan pembuatannya.

**Yang dibangun.**

- `CategoryDao.findCategoryByName` + `ProductRepositoryImpl.findOrCreateCategory`:
  nama dicocokkan tanpa peka huruf besar/kecil, jadi "minuman" saat "Minuman"
  sudah ada masuk ke kategori lama tanpa pesan error. `limit(1)`, bukan
  `getSingleOrNull` tanpa batas: tidak ada unique index di kolom itu, jadi baris
  kembar mungkin ada dan tidak boleh melempar.
- Opsi `+ Kategori baru` di dropdown form produk, dengan field nama yang muncul
  saat opsi itu dipilih. Nilainya `-1`, bukan `null`, karena `null` sudah dipakai
  validator `'Pilih kategori'` yang ada sejak langkah 4.
- Tab kategori hanya tampil untuk kategori yang punya **produk aktif**. Ini
  jawaban atas satu pertanyaan terbuka di tiket: `watchAllProducts` memang
  menyertakan `isActive = false`, jadi tanpa aturan ini kategori berisi barang
  nonaktif saja tetap memunculkan tabnya.
- `CategoryDao.updateCategory` dan `deleteCategory` **dihapus**, tidak ditinggal
  sebagai kode mati: tidak ada hapus/ganti nama kategori di desain ini.

**Efek samping yang disengaja: tab "Umum" hilang sendiri** begitu semua produk
punya kategori nyata. Barisnya tetap di DB dan tetap jadi tujuan FK
`products.categoryId` hasil seed — yang hilang hanya tabnya. Benar menurut
aturan, tapi akan terasa seperti kerusakan kalau tidak diharapkan.

**Dua hal yang tidak ada di tiket dan tetap dikerjakan**, karena cacatnya nyata:

1. Tab yang sedang dipilih bisa lenyap saat produk terakhirnya dipindah.
   Tanpa fallback, daftarnya jadi kosong tanpa tab aktif mana pun — pemilik akan
   melihat "Belum ada produk" padahal produknya ada.
2. Tes widget berbasis DB untuk aturan tab **ditulis lebih dulu dan gagal**:
   stream Drift tidak maju di `testWidgets`, jadi tab 'Minuman' tidak pernah
   muncul meski produknya sudah masuk DB. Filternya dipisah jadi fungsi lepas
   `categoriesWithActiveProducts` supaya bisa diuji dengan `test()` biasa.
   ADR-012 terbukti ulang di sini, bukan diasumsikan.

12 tes baru (158 → 170): 6 untuk cari-atau-buat (nama baru, sama persis, beda
kapitalisasi, berspasi, kosong ditolak, produk langsung memakai id barunya),
5 untuk filter tab, 1 tes widget untuk field nama yang wajib diisi.

---

## Desain v2 — D1: lapisan token

Rencana lengkapnya `docs/implementasi_design.md` (D1–D9, disusun 2026-11-09).
D1 dikerjakan dan diverifikasi pemilik 2026-11-09. Alasan tiap aturannya di
**ADR-046**.

**Yang berubah.** `AppColor` 52 → **17 token semantik**, `AppSpacing` →
`s1/s2/s3/s4/s6` + `tapMin/tapPrimary/rowMin`, `AppRadius` → `sm/md/lg/full`,
`AppTextStyle` → 9 gaya v2. 26 file, satu commit — lapisan token adalah
satu-satunya bagian desain v2 yang tidak bisa bertahap, karena menghapus satu
token memaksa semua pemanggilnya berubah bersamaan.

**Cara kerjanya**, supaya tidak diulang dengan cara yang salah: penggantian
berbatas kata lewat skrip, dengan penanda sementara pada hasilnya. Tanpa
penanda itu `surfaceContainerLowest` → `surface` → `bg` akan membuat semua
kartu putih berubah jadi warna halaman.

**Yang tidak bisa dimekaniskan**, dan memang dibaca satu per satu:

- Ke-25 `AppColor.outline` ternyata semuanya warna teks/ikon → `inkMuted`.
  Yang berperan sebagai garis semuanya `outlineVariant`, dan itu dipecah lagi:
  batas chip filter, kotak ikon, dan titik PIN → `lineStrong` (garis yang
  menandai kontrol, 3:1), sisanya `line` (hiasan).
- Delapan `headlineLg`/`headlineMd` tidak punya satu tujuan: omzet → `amount`,
  total dan kembalian → `stat`, judul sheet → `heading`, judul layar →
  `title`.

**Dua warna ternyata salah arti, bukan salah nama.** Pengingat backup dan
banner "perlu restok" keduanya merah karena v1 memakai `errorContainer` untuk
keduanya. `tokens.json` v2 menulis eksplisit bahwa `warning` berarti "badge
stok menipis, notice pengingat backup", dan merah hanya untuk Void / Habis /
error. Keduanya pindah ke pasangan kuning. Ini hanya kelihatan setelah token
punya arti, bukan dari pemetaan nama.

**Layar scanner sengaja dikecualikan.** 16 dari 24 hardcode `Colors.*` ada di
`barcode_scanner_screen.dart` dan tetap di sana: isinya gambar kamera, bukan
permukaan aplikasi. Alasannya ditulis sebagai komentar di `build` supaya tidak
"dirapikan" nanti (ADR-046).

**Nol tes baru, disengaja.** Tes yang mengunci nilai warna hanya menguji ulang
isi file token. Gerbangnya `flutter analyze` + 173 tes lama tetap hijau +
verifikasi pemilik di HP.

Yang akan langsung terasa beda: sudut membulat lebih besar (`radius.sm` 4 → 8,
`lg` 16 → 20), jarak antar bagian menyusut di 10 tempat (v2 tidak punya langkah
32px), dan bottom nav serta bottom sheet jadi putih.

---

## Desain v2 — D2–D5: navigasi, PIN sheet, Kasir, Pembayaran

Empat langkah dikerjakan sekaligus atas permintaan pemilik, diverifikasi di HP
2026-11-10. Alasan tiap keputusannya di **ADR-047** sampai **ADR-051**.

### D2 — Kasir jadi tab pertama, Dasbor dibuang

Empat tab **Kasir · Produk · Riwayat · Laporan**. `lib/features/dashboard/` dan
`low_stock_screen.dart` dihapus seluruhnya, beserta rute `dashboard` dan
`perlu-restok`. Pengaturan turun dari tab jadi ikon gear di app bar Laporan —
dan karena sekarang di-*push*, layar itu diberi app bar sendiri: tanpa itu
tidak ada jalan kembali. Ke mana tiap bagian Dasbor pindah: ADR-047.

**Yang paling mudah dibatalkan tanpa sengaja: `CartBloc` naik ke `main.dart`,**
di atas `StatefulShellRoute`. Kalau diturunkan lagi ke dalam `CashierScreen`,
pindah tab di tengah transaksi akan mengosongkan keranjang. Peringatannya
ditulis di tiga tempat (`main.dart`, `injection_container.dart`, dartdoc
`CashierScreen`) karena tidak ada tes yang bisa menjaganya (ADR-048).

### D3 — PIN jadi bottom sheet

`PinGate.require` membuka `showModalBottomSheet`, bukan rute penuh, jadi
transaksi yang sedang di-void tetap terlihat di belakangnya. Empat
pemanggilnya tidak disentuh sama sekali — itu gunanya pintu tunggal. Jeda
bertingkat 5s → 30s → 5 menit dan seluruh `PinRepository` tidak berubah: 9
tesnya hijau tanpa satu baris diubah, yang memang jadi syaratnya di rencana
(ADR-049).

### D4 — Kasir + "Sering dibeli" + PayBar

`ProductDao.watchFrequentProducts()` adalah query **kedua** di samping
`ReportDao.getBestSellers`, dan memang harus baru: yang lama mengelompokkan
nama snapshot tanpa id dan harga, jadi hasilnya tidak bisa dimasukkan ke
keranjang (ADR-050). 30 hari, transaksi lunas saja, produk aktif dan berstok,
limit 5 — lima tes repository menjaga tiap aturannya.

Chip kategori mengganti daftarnya: "Semua" + kotak cari kosong → terlaris;
pilih kategori atau ketik → daftar produk kategori/hasil cari. Keputusan
pemilik 2026-11-10, karena mockup tidak menjelaskan chip itu memfilter apa.

### D5 — Pembayaran jadi layar sendiri + Struk

`_PaymentPanel` keluar dari Kasir jadi `payment_screen.dart`. Tombol cepat
**tidak pernah menawarkan uang yang kurang dari total** — "Uang pas" plus
pecahan yang lebih besar saja; empat tes fungsi murni menjaganya. Struk
menggantikan layar bayar (`pushReplacement`), dapat `Notice` hijau dan tombol
"Transaksi baru" yang kembali ke Kasir dengan keranjang kosong. `int` rupiah
dan simpan-atomik tidak tersentuh.

### Bug yang ditemukan pemilik saat verifikasi: PayBar memenuhi layar

Keranjang dan daftar produk hilang sama sekali begitu satu produk masuk,
sementara tombol Bayar mengambang di tengah layar. Sebabnya `Scaffold` memberi
`bottomNavigationBar` batas longgar **setinggi layar penuh**, dan satu `Column`
tanpa `mainAxisSize` di dalam PayBar memakan semuanya — `body` jadi 0 px, dan
`ListView` setinggi nol tidak membangun satu pun anaknya. Perbaikannya
`MainAxisSize.min`, sekalian di batang bawah layar Struk yang bentuknya sama.

Ini kelas bug yang **bisa** dijaga `testWidgets`, karena yang diuji geometri
dan bukan data: `test/features/transaction/cashier_layout_test.dart` dibuktikan
merah sebelum perbaikan dan hijau sesudah, dengan semua repository dipalsukan
stream kosong supaya tidak ada DB dan tidak ada stream Drift yang menggantung
(ADR-051 — batas yang memperjelas ADR-012).

### Tes

173 → 189. Lima tes query terlaris, empat tes tombol cepat, lima tes chip
kategori + inisial avatar, dua tes geometri Kasir. `pin_flow_widget_test`
sekalian diperbaiki: penantian PBKDF2-nya dulu satu `Future.delayed(3s)` tetap
yang sempat kehabisan waktu saat suite penuh jalan paralel, sekarang menunggu
sampai UI-nya benar-benar berubah — dan filenya jadi 24 detik → 7 detik.

---

## Desain v2 — D6–D7: Produk, Tambah produk, Riwayat, Void

Diverifikasi pemilik di HP 2026-11-12. ADR-052 s/d ADR-055.

**`lib/core/widgets/` akhirnya lahir.** Rencana sudah menetapkan foldernya dan
aturannya ("tulis inline di layar pertama, angkat begitu layar kedua
membutuhkannya"), dan D6–D7 adalah tempat pemakai kedua itu muncul. Enam
widget diangkat dari salinan privat Kasir: `AppCard`, `AppChip` + `ChipRow`,
`AppAvatar` + `productInitial`, `AppBadge`, `SectionHeader`, `SearchRow`. Kasir
sekarang mengimpor, bukan menyimpan salinan — `cashier_screen.dart` susut 246
baris. Tidak ada widget yang dibuat "untuk nanti": `Field` tetap privat di form
produk karena pemakai keduanya baru ada di D8.

**Produk (D6).** Cari + scan, chip `Semua / Perlu restok · N / <kategori>`,
baris beravatar inisial, tombol "Tambah produk" melayang di atas bottom nav.
Chip restok memakai `lowStockProducts` yang sudah ada di state — tidak ada
query baru, dan banner yang tidak bisa diketuk sejak D2 ikut hilang. Badge
"Stok aman" dibuang: di daftar 86 produk, 86 badge hijau menenggelamkan 4 yang
perlu tindakan (ADR-052).

**Dua keputusan yang ditanyakan ke pemilik lebih dulu,** karena mockup dan
rencana tidak menjawabnya:

1. **Aksi baris produk.** Baris v2 tidak punya ikon, jadi Ubah/Restok/Koreksi/
   Hapus tidak punya tempat. Pemilik memilih sheet aksi saat baris diketuk
   (ADR-053) dari tiga pilihan; geser-baris ditolak karena menambah paket untuk
   aksi tanpa petunjuk di layar.
2. **Tombol scan di Produk.** Scanner selama ini terikat keranjang Kasir.
   Pemilik memilih "isi kolom cari dengan barcode-nya", jadi scanner dapat mode
   `returnsCode: true` yang mem-pop barcode tanpa menyentuh keranjang. Jalur
   Kasir tidak berubah sebaris pun.

**Tambah produk (D6).** Harga jual + modal berdampingan, stok awal +
"Ingatkan jika sisa" berdampingan, baris laba kotor per pcs berlatar
`primarySoft` (merah kalau rugi), catatan "Mengubah harga nanti perlu PIN"
ditulis di muka supaya sheet PIN tidak datang sebagai kejutan, dan "Simpan
produk" turun ke batang bawah. Tiga tes widget form lama tetap hijau.

**Riwayat (D7).** App bar dikosongkan — ikon ekspor yang mati dihapus dan ikon
"Cari transaksi" di mockup tidak dibangun (keputusan pemilik 6), menutup satu
baris utang. Chip `Hari ini / Kemarin / 7 hari / Pilih tanggal`, judul bagian
"<rentang> · N transaksi" + jumlah void, total dicoret untuk yang void supaya
tidak ikut dijumlahkan pemilik saat membaca daftar.

**Satu perubahan menembus ke lapisan data.** `watchHistory` dapat parameter
`until` (DAO + interface + impl): "Kemarin" dan satu hari pilihan butuh batas
atas, dan menyaringnya di memori berarti menarik seluruh riwayat lebih dulu.
`historyRange` dipisah jadi fungsi murni dan diuji 6 kasus — termasuk bahwa
"Kemarin" tidak menyentuh hari ini, aturan hari kalender yang sama dengan
`ReportPeriod.rangeFrom`.

**Void jadi satu sheet (D7).** Ringkasan dampak, chip alasan, PIN pad, dan
tombol merah dalam satu tampilan; `_VoidReasonDialog` dan alur dua langkah
dihapus. PIN sengaja **tidak** auto-submit di sheet ini — tombol "Void
transaksi" yang memicu, supaya alasan tidak bisa terlewat dan pemilik masih
bisa batal setelah mengetik PIN (ADR-054). `PinBloc`/`PinRepository` tidak
disentuh dan `voidTransaction` tetap dipanggil layar detail, jadi 9 tes PIN dan
seluruh tes void di repository hijau tanpa diubah.

**Bug yang ditemukan pemilik saat verifikasi D6.** Men-scan barcode produk yang
**sudah terdaftar** dari layar Produk melempar assert `!_debugLocked` di
`navigator.dart`. Penyebabnya bukan lookup produk — di mode itu tidak ada
lookup: barcode cetak asli terbaca berkali-kali per detik, deteksi kedua jatuh
di celah `await HapticFeedback` dan memanggil `pop()` di tengah `pop()`
pertama. Penjaganya sudah ada di file itu sejak awal (`_isBusy`) dan jalur
keranjang memakainya; early-return mode baru ditulis di atas blok `setState`
itu sehingga melewatinya. Perbaikannya satu baris, memakai penjaga yang sama
(ADR-055). Aturannya ikut ditulis di `AGENTS.md` §3 karena ini aturan yang
harus dipatuhi **saat menulis kode**, bukan hanya catatan keputusan (ADR-025).

**Tes: 189 → 205.** `visibleProducts` 9 tes (termasuk bahwa produk stok 0 ikut
di chip restok), `historyRange` 6 tes, dan 1 tes repository untuk filter
`until`. Tidak ada tes baru untuk bug scanner — lihat ADR-055 untuk alasannya
dan pemeriksaan manual penggantinya.

---

## Desain v2 — D8–D9: Laporan, Pengaturan, sapu bersih

Diverifikasi pemilik di HP 2026-11-12. ADR-056 s/d ADR-059. **Langkah terakhir
`docs/implementasi_design.md`** — sembilan dari sembilan.

**Laporan (D8).** Tiga angka saja: Omzet besar di atas, lalu Laba kotor dan
Transaksi berdampingan. `itemCount` dan `averageSale` tetap dihitung
repository tapi tidak lagi ditampilkan — rencana menetapkan tiga angka, dan
lima angka di satu layar membuat tidak ada yang menonjol. Di bawahnya
"Terlaris" dalam `AppCard`, ringkasan stok rendah tiga teratas dengan "Lihat
semua" yang pindah ke tab Produk, dan satu baris penutup "Transaksi yang sudah
di-void tidak dihitung" — pertanyaan yang pasti muncul kalau omzetnya terasa
kurang. `report_stats.dart` (`StatBox` + `BestSellerList`) dihapus karena
kehilangan seluruh pemakainya.

**Dua keputusan yang ditanyakan ke pemilik lebih dulu:**

1. **Laba kotor ber-PIN.** Rencana sengaja menyisakan ini untuk pemilik.
   Dipilih "angkanya disembunyikan sampai PIN benar" — bukan sekadar label
   ber-PIN. Jadi yang terlihat `••••••` + ikon kunci, dan angkanya **tidak ada
   di widget tree** sama sekali sebelum PIN benar (ADR-057).
2. **Preset periode.** Mockup menulis "30 hari", rencana tidak menyebut
   keduanya. Dipilih "Bulan ini" kalender — tanggal 1 sampai hari ini — karena
   itu yang dipakai pemilik saat menghitung setoran bulanan (ADR-056).
   `ReportPeriod.days` yang tetap dihapus: bulan panjangnya 28–31 hari.

**Pengaturan (D8).** Kartu Backup & restore dengan tanggal backup terakhir +
badge "Perlu backup", lalu bagian Toko: Info toko, Ganti/Buat PIN dengan badge
status, dan Tentang Henshin tanpa ketukan. `BackupReminder` akhirnya punya
rumah lagi setelah Dasbor dibuang di D2 (ADR-047), dan kehilangan tombolnya
sendiri — dua tombol dengan aksi identik berjarak 24 px hanya membuat ragu
mana yang benar. Dua baris dummy "Pajak (PPN) 11%" dan "Printer thermal BT-01"
dihapus: pajak out-of-scope (AGENTS.md §6) dan printernya belum ada
(langkah 9). Baris "Isi: N produk · N transaksi" di mockup tidak dibangun
(keputusan pemilik 5) — tidak ada query hitung baru.

**Sapu bersih (D9).** Empat ikon bottom nav jadi outlined semua: ini
satu-satunya tempat empat ikon berdiri bersebelahan, jadi satu yang solid
langsung tampak lebih berat. `fontFeatures: tabularFigures` turun ke `body`,
`label`, dan `caption`, bukan hanya gaya uang yang besar — harga per baris
produk memakai `label` dan `#id · jam` di Riwayat memakai `body`, dan keduanya
bertumpuk di satu kolom. `AppColor.primaryPressed` akhirnya dipakai lewat
`elevatedButtonTheme`: tokennya dipakai, bukan dihapus, karena yang hilang
kalau dihapus adalah aturan desainnya. `AppRadius.lgAll` justru dihapus —
sudut 20 hanya dipakai `sheetTop`. Dan `test/widget_test.dart`, template
counter bawaan yang membuat `flutter test` tanpa argumen gagal **sejak hari
pertama proyek**, ikut dibuang; perintahnya sekarang jalan dan AGENTS.md §4
tidak lagi menyuruh mengabaikannya.

**Dua bug yang lahir dari perubahan saya sendiri di langkah ini,** keduanya
ketemu sebelum sampai HP:

- `CrossAxisAlignment.stretch` di dalam `ListView` meminta tinggi tak terbatas
  dan langsung crash. Layar Laporan versi pertama D8 tidak akan bisa dibuka
  sama sekali. Ditemukan tes widget baru, diperbaiki dengan `IntrinsicHeight`
  (ADR-058).
- `styleFrom(...).copyWith(backgroundColor: ...)` mengganti warna untuk
  **semua** `WidgetState` sekaligus, jadi menambahkan warna tekan ikut
  menghidupkan kembali tombol yang sedang mati — "Menyimpan..." dan "Bayar"
  akan tampak bisa ditekan padahal `onPressed` null (ADR-059).

**Tes: 205 → 210.** Tiga tes rentang `Bulan ini` di repository laporan
(termasuk 15 Maret → mulai 1 Maret, dan 2 Nov masuk sementara 31 Okt tidak),
dan dua tes widget `report_profit_lock_test.dart` yang mengunci sifat
keamanannya: `Rp 312.000` harus `findsNothing` sebelum PIN. Menyembunyikan
angka dengan `Opacity` atau warna transparan lolos mata tapi gagal di tes itu
— itu memang tujuannya.

---

## Utang teknis yang masih terbuka

| Hal | Dampak |
|---|---|
| `settings.schemaVersion` hanya diisi saat seed | Jadi basi setelah bump versi berikutnya. Ditandai `shortcut:` di kode |
| `decrementStock`/`incrementStock` lama di `ProductDao` tidak menulis ledger dan **tidak dipakai siapa pun** | Langkah 6 dan 11 tidak memakainya (keduanya lewat `TransactionDao`). Sekarang murni mati — kandidat dihapus |
| Laba kotor tetap terbuka selama layarnya hidup | Sekali PIN benar, angkanya terlihat sampai periode diganti atau aplikasi ditinggalkan. Tidak ada timeout. Kalau HP dipegang orang lain saat layar masih terbuka, angkanya terbaca (ADR-057) |
| `itemCount` dan `averageSale` dihitung tapi tidak ditampilkan di mana pun | Keduanya masih di `SalesReport` dan masih diuji. Dipakai tes, bukan layar — hapus kalau D8 bertahan beberapa rilis, jangan hapus sekarang hanya karena tidak terlihat |
| Pengaturan tidak menampilkan isi database | Baris "Isi: N produk · N transaksi" di mockup tidak dibangun (keputusan pemilik 5). Kalau nanti dibutuhkan, itu dua query hitung baru, bukan sekadar label |
| Riwayat pergerakan stok masih belum punya tampilan, dan sekarang Laporan juga tidak | Ledger ditulis lengkap (termasuk oleh void) tapi satu-satunya cara melihatnya tetap membuka DB langsung |
| Layar riwayat + detail transaksi belum punya tes widget | Logikanya teruji di tes repository; rentang chip sekarang dijaga `historyRange` (6 tes), tapi navigasi dan `VoidSheet` hanya terverifikasi manual (ADR-012, ADR-054) |
| Layar `StockSheet`, jalur PinGate-saat-ubah-harga, dan alur simpan form sampai layarnya tertutup belum punya tes | Terverifikasi manual, bukan otomatis. Celah inilah yang melewatkan bug ADR-013. Lihat ADR-012 |
| Angka laporan menjumlahkan header transaksi di memori | Preset terpanjang sekarang "Bulan ini" (28–31 hari, ADR-056). Aman untuk satu warung; perlu pindah ke agregat SQL (dengan offset zona waktu eksplisit) kalau datanya jadi tahunan. ADR-032 |
| `ReportScreen` hanya diuji pada kunci laba dan judul periode | 2 tes widget (ADR-057) + 16 tes repository. Yang **tidak** diuji: ringkasan stok rendah, "Lihat semua" yang pindah tab, baris Terlaris, dan jalur PIN benar — `PinGate` butuh `sl<PinRepository>()` yang tidak dipalsukan di tes itu (ADR-012) |
| Barcode yang beda hanya nol di depan tidak dicocokkan | Kemasan UPC-A mencetak 12 digit sementara scanner bisa melaporkannya sebagai EAN-13 dengan nol tambahan. Pencocokan longgar sengaja ditolak: dua produk yang beda hanya nol di depan akan saling tertukar (ADR-044) |
| Produk yang pernah terjual tidak bisa dihapus selamanya | Hanya bisa dinonaktifkan: hilang dari kasir, tetap di daftar produk. Void tidak membebaskannya. Kalau daftarnya jadi penuh, yang dibutuhkan fitur "sembunyikan dari daftar produk", bukan hapus (ADR-045) |
| Nama kategori tidak bisa dihapus atau diganti dari dalam aplikasi | Disengaja (ADR-038): salah ketik hilang dari layar begitu produknya dipindah, tapi barisnya menumpuk di DB selamanya. Diterima karena tidak ada laporan yang membacanya |
| Kategori bisa lahir tanpa produk | Kalau penyimpanan produk gagal setelah kategorinya dibuat, kategori itu tetap ada. Sengaja tidak dibungkus satu transaksi karena tab kosong tidak pernah ditampilkan (ADR-038) |
| `lower()` SQLite hanya melipat ASCII | "Café" dan "café" masih bisa jadi dua kategori. Ditandai `shortcut:` di `CategoryDao` (ADR-038) |
| "Keranjang bertahan saat pindah tab" tidak dijaga tes otomatis | Yang menentukan bukan isi `CartBloc` tapi posisi providernya di widget tree (ADR-048). Tes bloc untuk itu hanya akan menguji ulang `flutter_bloc`, jadi ini terverifikasi manual saja |
| Field uang diterima tidak memakai pemisah ribuan | Tombol cepat mengisi `50000`, bukan `50.000`. Pengelompokan saat mengetik butuh `TextInputFormatter` sendiri; ditandai `shortcut:` di `payment_screen.dart` |
| Batas 30 hari daftar "Sering dibeli" dihitung sekali saat stream dibuat | Kalau aplikasi dibiarkan terbuka berhari-hari, jendelanya ikut menua. Ditandai `shortcut:` di `ProductDao.watchFrequentProducts` (ADR-050) |
| Skenario UAT tidak pernah ditulis | Langkah 15 diuji manual tanpa artefak, jadi uji berikutnya setelah perubahan besar (desain v2) tidak punya pembanding yang bisa diulang — hanya ingatan |
| Crash-free ≥99% tidak terukur | Tidak ada crash terlihat saat uji, tapi itu bukan rate. Menghitungnya butuh telemetri, yang bertabrakan dengan offline-only (ADR-042) |
| Metrik "produk masuk keranjang ≤2 detik" belum terukur | Jalur scan lengkap baru benar-benar jalan sejak 2026-11-08 (perbaikan cari barcode), dan kecepatannya belum pernah diukur dengan stopwatch — termasuk sesudah halaman scan jadi potrait |
| Layar Produk belum punya tes yang me-render daftar terisi | Tes yang ada hanya menguji daftar kosong + validator form. Baris produk, badge, dan chip hanya terverifikasi manual — lubang yang sempat membuat saya salah menduga penyebab bug scanner |
| Bug di dalam layar scanner tidak bisa dijaga tes otomatis | `MobileScannerController` butuh platform channel kamera yang tidak ada di `flutter test`, dan memalsukannya dilarang ADR-012. Dua bug scanner (ADR-044, ADR-055) sama-sama hanya tertangkap mata pemilik di HP |
| Kalender "Pilih tanggal" di Riwayat berbahasa Inggris | `showDatePicker` memakai locale ambient dan app ini belum pernah menginisialisasi locale `intl`. Sama sebabnya dengan tanggal yang ditulis `dd/MM/yyyy`, bukan nama bulan |
| Angka chip "Perlu restok · N" lebih besar dari jumlah badge `Sisa N` yang terlihat | Disengaja: chip ikut menghitung produk habis, badge tidak (produk habis sudah dapat badge `Habis`). Selisihnya benar, jangan diseragamkan — ADR-052 |
| `ProductActionSheet` membuka Hapus satu ketukan dari daftar | Lebih aman dari menu tiga titik yang dulu, tapi produk yang belum pernah terjual tetap bisa hilang permanen setelah satu dialog konfirmasi (ADR-053) |
| Impl cetak ESC/POS Bluetooth belum ada | Langkah 9 belum tuntas. Butuh printer 58mm fisik + spike 1 hari (PRD §3.4). Metrik "50× cetak ≥95% sukses" belum terukur |
| Jalur share khusus PDF struk belum terkonfirmasi di device | `SharePlus.instance.share` sendiri sudah terbukti jalan lewat backup langkah 13, jadi yang tersisa hanya jalur PDF-nya (ADR-026 + rebuild penuh belum pernah berjalan bersamaan di HP) |
| Peringatan `Courier has no Unicode support` di log | Hanya informatif; karakter non-Latin1 dipetakan ke `?` di PDF (ADR-027). Ganti font Unicode kalau katalog butuh |
| `ReceiptPreviewScreen` dan `StoreInfoScreen` belum punya tes | Sama seperti layar lain (ADR-012) |
| File backup hanya ada di cache aplikasi | Boleh dibuang Android kapan saja. `lastBackupAt` bisa mencatat backup yang tidak pernah terkirim ke mana pun, karena Android sering tidak bisa membedakan "dibagikan" dari "sheet ditutup" (ADR-035) |
| Salinan pengaman restore tinggal di cache | Satu file `henshin-sebelum-restore.sqlite` yang selalu ditimpa, dan Android boleh menghapus cache kapan pun. Jaring untuk beberapa menit, bukan backup (ADR-040) |
| Tidak ada cara memulihkan salinan pengaman dari dalam aplikasi | Kalau pemilik memulihkan file yang salah, mengembalikannya butuh ADB atau bantuan developer. Belum diputuskan apakah layak satu tombol (ADR-040) |
| Restore memaksa aplikasi ditutup | Semua DAO di get_it memegang koneksi yang sudah mati setelah file ditukar, jadi satu-satunya jalan aman adalah `exit(0)` yang benar-benar mematikan proses. Rebuild in-process sengaja ditolak (ADR-039) |
| `RestoreAction` belum punya tes widget | Validasi + penukaran file teruji di 13 tes repository; dialog konfirmasi, picker, dan dialog "tutup aplikasi" hanya terverifikasi manual (ADR-012) |
| `file_picker` menambah plugin native baru | Hot restart setelah ini memberi `MissingPluginException`; butuh `flutter run` penuh (ADR-025). `sqlite3` hanya dinaikkan dari transitif ke langsung, tanpa unduhan baru |
| Ambang basi memakai `> 7` hari | Banner baru muncul di hari ke-8, persis seperti teks rencana. Kalau yang dimaksud hari ke-7, ubah `backupStaleAfterDays` atau operatornya di `store_info.dart` |
| `BackupReminder` dan baris "Backup data" belum punya tes widget | Logikanya teruji di 14 tes repository + entity; banner dan badge hanya terverifikasi manual (ADR-012) |
