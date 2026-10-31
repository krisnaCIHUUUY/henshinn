# Progress Henshin POS

Status eksekusi `docs/implementasi.md`. Diperbarui 2026-10-31.

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
| 6–15 | Kasir, struk, printer, riwayat/void, laporan, backup, hardening | ⬜ belum |

Fondasi (1–3) dan F2 Produk & Stok (4–5) selesai. Berikutnya langkah 6:
keranjang + bayar + simpan atomik — ditandai **⚠ RISIKO TINGGI** di rencana.

**Verifikasi saat ini:** 58 tes lolos, `flutter analyze` bersih, dan alur
langkah 1–5 sudah dicoba manual di device fisik oleh pemilik repo.

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

---

## Utang teknis yang masih terbuka

| Hal | Dampak |
|---|---|
| `test/widget_test.dart` masih template counter bawaan yang rusak | `flutter test` tanpa argumen gagal (58 lolos, 1 gagal). AGENTS.md menandainya "ignore", belum diputuskan mau dihapus |
| `settings.schemaVersion` hanya diisi saat seed | Jadi basi setelah bump versi berikutnya. Ditandai `shortcut:` di kode |
| `decrementStock`/`incrementStock` lama di `ProductDao` tidak menulis ledger | Kalau langkah 6 memakainya, ledger bolong. Pakai `TransactionDao.createTransactionWithItems` |
| `setting_screen.dart` memuat baris dummy "Pajak (PPN) 11%" dan "Export laporan CSV" | Keduanya di luar scope (AGENTS.md §5), perlu dibersihkan sebelum rilis |
| Riwayat pergerakan stok belum punya tampilan | Ledger ditulis tapi belum bisa dilihat pemilik. Bahan langkah 10 |
| Layar `StockSheet`, `LowStockScreen`, dan jalur PinGate-saat-ubah-harga belum punya tes | Terverifikasi manual, bukan otomatis. Lihat ADR-012 |
| `.claude/` belum masuk `.gitignore` | Konfigurasi lokal berisiko ikut ter-commit |
