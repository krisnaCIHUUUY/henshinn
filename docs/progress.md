# Progress Henshin POS

Status eksekusi `docs/implementasi.md`. Diperbarui 2026-11-01 (langkah 1–12).

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
| 7 | Scan barcode kamera + fallback | ✅ kode selesai, **uji device fisik belum** |
| 8 | Model `Receipt` + preview + PDF/share | ✅ selesai |
| 9 | Cetak ESC/POS Bluetooth | 🟡 **sebagian**: `PrinterService` + impl PDF selesai; impl Bluetooth ditunda sampai printer tiba |
| 10 | Riwayat + detail + cetak ulang | ✅ selesai |
| 11 | Void ber-PIN + alasan + stok kembali | ✅ selesai |
| 12 | Dashboard hari ini + laporan preset + produk terlaris | ✅ selesai |
| 13–15 | Backup, restore, hardening | ⬜ belum |

Fondasi (1–3), F2 Produk & Stok (4–5), dan F1 Kasir + scan + struk (6–8)
selesai di sisi kode. Langkah 9 sengaja berhenti di interface + fallback PDF
sesuai PRD §2.8 ("selama printer belum ada, pengembangan memakai preview dan
PDF"); impl ESC/POS menunggu printer fisik + spike 1 hari (PRD §3.4).
F3 Riwayat & Void (10–11) dan F4 Dashboard & Laporan (12) selesai. Berikutnya
F5 Backup & Restore (13–14) — satu-satunya safety net data, tidak boleh
dipotong (PRD §1.6).

**Verifikasi saat ini:** 128 tes lolos, `flutter analyze` bersih.

Uji manual di device oleh pemilik repo: langkah 1–5 dan 10–12 ✅; langkah 6
(kasir) dan 8 (struk) sebagian — lima bug ditemukan dan sudah diperbaiki, lihat
"Perbaikan setelah verifikasi manual". **Belum pernah diuji di HP:** scanner barcode
(langkah 7) dan share sheet PDF — keduanya ikut terkubur di APK lama, jadi
butuh `flutter run` penuh, bukan hot restart.

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

## Perbaikan setelah verifikasi manual

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

## Utang teknis yang masih terbuka

| Hal | Dampak |
|---|---|
| `test/widget_test.dart` masih template counter bawaan yang rusak | `flutter test` tanpa argumen gagal (128 lolos, 1 gagal). AGENTS.md menandainya "ignore", belum diputuskan mau dihapus |
| `settings.schemaVersion` hanya diisi saat seed | Jadi basi setelah bump versi berikutnya. Ditandai `shortcut:` di kode |
| `decrementStock`/`incrementStock` lama di `ProductDao` tidak menulis ledger dan **tidak dipakai siapa pun** | Langkah 6 dan 11 tidak memakainya (keduanya lewat `TransactionDao`). Sekarang murni mati — kandidat dihapus |
| `setting_screen.dart` memuat baris dummy "Pajak (PPN) 11%" dan "Export laporan CSV" | Keduanya di luar scope (AGENTS.md §5), perlu dibersihkan sebelum rilis |
| Riwayat pergerakan stok belum punya tampilan | Ledger ditulis (termasuk oleh void) tapi belum bisa dilihat pemilik. Riwayat langkah 10 menampilkan transaksi, bukan ledger |
| Layar riwayat + detail transaksi belum punya tes widget | Logikanya teruji di tes repository, navigasi dan dialog alasan void hanya terverifikasi manual (ADR-012, ADR-028) |
| Ikon ekspor di header riwayat masih mati | Peninggalan UI dummy; ekspor CSV di luar scope (AGENTS.md §5). Perlu dihapus atau diganti fungsi lain |
| Layar `StockSheet`, `LowStockScreen`, jalur PinGate-saat-ubah-harga, dan alur simpan form sampai layarnya tertutup belum punya tes | Terverifikasi manual, bukan otomatis. Celah inilah yang melewatkan bug ADR-013. Lihat ADR-012 |
| Sapaan dashboard masih hardcoded `'Henshin Store · kasir 1'` | Nama toko asli sudah ada di tabel `settings` sejak langkah 8 tapi tidak dipakai di header dashboard |
| Blok `_RestockList` di `dashboard_screen.dart` masih di-comment | Peninggalan UI dummy; `LowStockScreen` sudah menanganinya. Kandidat hapus |
| Angka 30 hari menjumlahkan header transaksi di memori | Aman untuk satu warung; perlu pindah ke agregat SQL (dengan offset zona waktu eksplisit) kalau datanya jadi tahunan. ADR-032 |
| Dashboard dan `ReportScreen` belum punya tes widget | Angkanya dijaga 13 tes repository; chart fl_chart merender di canvas jadi tes widget hanya bisa memastikan widget-nya ada |
| `.claude/` belum masuk `.gitignore` | Konfigurasi lokal berisiko ikut ter-commit |
| Scanner belum pernah dijalankan di device fisik | Metrik PRD "produk masuk keranjang ≤2 detik" belum terukur. Emulator tidak cukup (PRD §1.6) |
| Impl cetak ESC/POS Bluetooth belum ada | Langkah 9 belum tuntas. Butuh printer 58mm fisik + spike 1 hari (PRD §3.4). Metrik "50× cetak ≥95% sukses" belum terukur |
| Share sheet PDF belum terkonfirmasi berhasil di device | Dua perbaikan (ADR-026 + rebuild penuh) belum pernah berjalan bersamaan di HP. `SharePlus.instance.share` sendiri belum pernah dikonfirmasi jalan di Android |
| Peringatan `Courier has no Unicode support` di log | Hanya informatif; karakter non-Latin1 dipetakan ke `?` di PDF (ADR-027). Ganti font Unicode kalau katalog butuh |
| `ReceiptPreviewScreen` dan `StoreInfoScreen` belum punya tes | Sama seperti layar lain (ADR-012) |
