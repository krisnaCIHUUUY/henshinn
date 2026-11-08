# Progress Henshin POS

Status eksekusi `docs/implementasi.md`. Diperbarui 2026-11-08 (langkah 1–15, plus orientasi scan, perbaikan cari
barcode, dan kategori produk).

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
(langkah 9), satu pekerjaan yang masih diparkir pemilik di `.scratch/` (desain
UI v2 — orientasi scanner dan kategori produk sudah dikerjakan), dan dua metrik
PRD yang belum bisa diukur — lihat tabel utang teknis.

**Verifikasi saat ini:** 173 tes lolos, `flutter analyze` bersih.

Uji manual di device oleh pemilik repo: langkah 1–5, 7, dan 10–15 ✅; langkah 6
(kasir) dan 8 (struk) sebagian — lima bug ditemukan dan sudah diperbaiki, lihat
"Perbaikan setelah verifikasi manual". Langkah 13 sekaligus membuktikan
`SharePlus.instance.share` memang jalan di Android, yang sebelumnya belum pernah
terkonfirmasi; langkah 14 menambah `file_picker` ke daftar yang sudah
terbukti di HP — sementara `SystemNavigator.pop()` justru terbukti **tidak**
cukup, lihat "Perbaikan setelah verifikasi manual". Langkah 15 menutup lubang
terlama: **scanner barcode akhirnya jalan di HP fisik**, yang sejak langkah 7
hanya pernah diuji di emulator.

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

## Utang teknis yang masih terbuka

| Hal | Dampak |
|---|---|
| `test/widget_test.dart` masih template counter bawaan yang rusak | `flutter test` tanpa argumen gagal (173 lolos, 1 gagal). AGENTS.md menandainya "ignore", belum diputuskan mau dihapus |
| `settings.schemaVersion` hanya diisi saat seed | Jadi basi setelah bump versi berikutnya. Ditandai `shortcut:` di kode |
| `decrementStock`/`incrementStock` lama di `ProductDao` tidak menulis ledger dan **tidak dipakai siapa pun** | Langkah 6 dan 11 tidak memakainya (keduanya lewat `TransactionDao`). Sekarang murni mati — kandidat dihapus |
| `setting_screen.dart` masih memuat baris dummy "Pajak (PPN) 11%" dan "Printer thermal BT-01" | Keduanya di luar scope atau belum ada (AGENTS.md §6, langkah 9), perlu dibersihkan sebelum rilis. Baris "Export laporan CSV" sudah dihapus di langkah 13 |
| Riwayat pergerakan stok belum punya tampilan | Ledger ditulis (termasuk oleh void) tapi belum bisa dilihat pemilik. Riwayat langkah 10 menampilkan transaksi, bukan ledger |
| Layar riwayat + detail transaksi belum punya tes widget | Logikanya teruji di tes repository, navigasi dan dialog alasan void hanya terverifikasi manual (ADR-012, ADR-028) |
| Ikon ekspor di header riwayat masih mati | Peninggalan UI dummy; ekspor CSV di luar scope (AGENTS.md §6). Perlu dihapus atau diganti fungsi lain |
| Layar `StockSheet`, `LowStockScreen`, jalur PinGate-saat-ubah-harga, dan alur simpan form sampai layarnya tertutup belum punya tes | Terverifikasi manual, bukan otomatis. Celah inilah yang melewatkan bug ADR-013. Lihat ADR-012 |
| Sapaan dashboard masih hardcoded `'Henshin Store · kasir 1'` | Nama toko asli sudah ada di tabel `settings` sejak langkah 8 tapi tidak dipakai di header dashboard |
| Blok `_RestockList` di `dashboard_screen.dart` masih di-comment | Peninggalan UI dummy; `LowStockScreen` sudah menanganinya. Kandidat hapus |
| Angka 30 hari menjumlahkan header transaksi di memori | Aman untuk satu warung; perlu pindah ke agregat SQL (dengan offset zona waktu eksplisit) kalau datanya jadi tahunan. ADR-032 |
| Dashboard dan `ReportScreen` belum punya tes widget | Angkanya dijaga 13 tes repository; chart fl_chart merender di canvas jadi tes widget hanya bisa memastikan widget-nya ada |
| Barcode yang beda hanya nol di depan tidak dicocokkan | Kemasan UPC-A mencetak 12 digit sementara scanner bisa melaporkannya sebagai EAN-13 dengan nol tambahan. Pencocokan longgar sengaja ditolak: dua produk yang beda hanya nol di depan akan saling tertukar (ADR-044) |
| Produk yang pernah terjual tidak bisa dihapus selamanya | Hanya bisa dinonaktifkan: hilang dari kasir, tetap di daftar produk. Void tidak membebaskannya. Kalau daftarnya jadi penuh, yang dibutuhkan fitur "sembunyikan dari daftar produk", bukan hapus (ADR-045) |
| Nama kategori tidak bisa dihapus atau diganti dari dalam aplikasi | Disengaja (ADR-038): salah ketik hilang dari layar begitu produknya dipindah, tapi barisnya menumpuk di DB selamanya. Diterima karena tidak ada laporan yang membacanya |
| Kategori bisa lahir tanpa produk | Kalau penyimpanan produk gagal setelah kategorinya dibuat, kategori itu tetap ada. Sengaja tidak dibungkus satu transaksi karena tab kosong tidak pernah ditampilkan (ADR-038) |
| `lower()` SQLite hanya melipat ASCII | "Café" dan "café" masih bisa jadi dua kategori. Ditandai `shortcut:` di `CategoryDao` (ADR-038) |
| Skenario UAT tidak pernah ditulis | Langkah 15 diuji manual tanpa artefak, jadi uji berikutnya setelah perubahan besar (desain v2) tidak punya pembanding yang bisa diulang — hanya ingatan |
| Crash-free ≥99% tidak terukur | Tidak ada crash terlihat saat uji, tapi itu bukan rate. Menghitungnya butuh telemetri, yang bertabrakan dengan offline-only (ADR-042) |
| Metrik "produk masuk keranjang ≤2 detik" belum terukur | Jalur scan lengkap baru benar-benar jalan sejak 2026-11-08 (perbaikan cari barcode), dan kecepatannya belum pernah diukur dengan stopwatch — termasuk sesudah halaman scan jadi potrait |
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
