# Progress Henshin POS

Status eksekusi `docs/implementasi.md`. Diperbarui 2026-10-31 (langkah 1–7).

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
| 8–15 | Struk, printer, riwayat/void, laporan, backup, hardening | ⬜ belum |

Fondasi (1–3), F2 Produk & Stok (4–5), dan F1 Kasir + scan (6–7) selesai di
sisi kode. Berikutnya langkah 8: model `Receipt` + preview + PDF/share.

**Verifikasi saat ini:** 84 tes lolos, `flutter analyze` bersih. Alur langkah
1–5 sudah dicoba manual di device fisik oleh pemilik repo; **langkah 6 dan 7
belum** — kasir dan scanner masih menunggu uji di HP.

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

## Perbaikan setelah verifikasi manual

- **Form tambah produk tidak pernah tertutup setelah simpan sukses** (dilaporkan
  pemilik). `ProductState.writeCount` ditambahkan sebagai penanda selesainya
  operasi tulis; `status` saja tidak cukup. Lihat ADR-013.
- **Layar kasir tidak punya tombol keluar** (dilaporkan pemilik). Dashboard
  membukanya dengan `context.go` yang mengganti stack navigasi, jadi AppBar
  tidak memunculkan tombol kembali **dan** tombol back fisik keluar dari
  aplikasi. Diganti `context.push` + tombol kembali eksplisit + konfirmasi
  kalau keranjang masih terisi. Lihat ADR-020.

---

## Utang teknis yang masih terbuka

| Hal | Dampak |
|---|---|
| `test/widget_test.dart` masih template counter bawaan yang rusak | `flutter test` tanpa argumen gagal (84 lolos, 1 gagal). AGENTS.md menandainya "ignore", belum diputuskan mau dihapus |
| `settings.schemaVersion` hanya diisi saat seed | Jadi basi setelah bump versi berikutnya. Ditandai `shortcut:` di kode |
| `decrementStock`/`incrementStock` lama di `ProductDao` tidak menulis ledger dan **tidak dipakai siapa pun** | Langkah 6 tidak memakainya (penjualan lewat `TransactionDao.createSale`). Jebakan untuk langkah 11 (void) — pakai `TransactionDao.voidTransaction`. Kandidat dihapus |
| `setting_screen.dart` memuat baris dummy "Pajak (PPN) 11%" dan "Export laporan CSV" | Keduanya di luar scope (AGENTS.md §5), perlu dibersihkan sebelum rilis |
| Riwayat pergerakan stok belum punya tampilan | Ledger ditulis tapi belum bisa dilihat pemilik. Bahan langkah 10 |
| Layar `StockSheet`, `LowStockScreen`, jalur PinGate-saat-ubah-harga, dan alur simpan form sampai layarnya tertutup belum punya tes | Terverifikasi manual, bukan otomatis. Celah inilah yang melewatkan bug ADR-013. Lihat ADR-012 |
| `.claude/` belum masuk `.gitignore` | Konfigurasi lokal berisiko ikut ter-commit |
| Scanner belum pernah dijalankan di device fisik | Metrik PRD "produk masuk keranjang ≤2 detik" belum terukur. Emulator tidak cukup (PRD §1.6) |
