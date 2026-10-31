# Keputusan Arsitektur — Henshin POS

Keputusan yang diambil selama eksekusi `docs/implementasi.md` dan **tidak** bisa
disimpulkan dari kode saja: yang dipilih, alternatif yang ditolak, dan alasannya.
Dibaca sebelum mengubah area terkait supaya keputusan ini tidak dibatalkan tanpa
sengaja.

Dicatat 2026-10-31, mencakup langkah 1–5. Status progres: `docs/progress.md`.

---

## ADR-001 — Koneksi DB dibuka di `injection_container`, bukan di `AppDatabase`

`AppDatabase(super.e)` tetap menerima `QueryExecutor` dari luar; `driftDatabase()`
dipanggil saat registrasi DI.

**Alternatif ditolak:** pola docs Drift `AppDatabase([QueryExecutor? e])` dengan
opener default di dalam kelasnya.

**Alasan:** tes bisa menyuntik `NativeDatabase.memory()` atau koneksi dari
`SchemaVerifier` tanpa menyentuh kode produksi. Seluruh tes DB bergantung pada
ini.

## ADR-002 — File DB di application support dir

`driftDatabase(name: 'henshin', native: DriftNativeOptions(databaseDirectory:
getApplicationSupportDirectory))`.

**Alasan:** default `drift_flutter` adalah documents dir yang terekspos ke file
manager user dan lebih mudah terhapus. Backup/restore (langkah 13–14) memakai
`VACUUM INTO` ke share sheet, jadi tidak butuh DB di lokasi yang terlihat user.

## ADR-003 — DI hanya mendaftarkan yang dikonsumsi

DAO/usecase ditambahkan ke `initDependencies()` saat fiturnya digarap, bukan
sekaligus di awal.

**Alasan:** menghindari wiring mati. Konsekuensi: menambah fitur berarti juga
menambah registrasi — kalau lupa, `flutter analyze` tetap bersih tapi app
meledak di runtime. Karena itu ada `test/injection_container_test.dart` yang
me-resolve seluruh grafik DI (memalsukan `path_provider` + secure storage).

## ADR-004 — Migrasi memakai tooling snapshot resmi Drift

`build.yaml` → `drift_schemas/drift_schema_v*.json` →
`lib/core/database/app_database.steps.dart` → `stepByStep(...)`.

**Alternatif ditolak:** `onUpgrade` manual dengan `if (from < n)`.

**Alasan:** PRD §2.6 mewajibkan "setiap perubahan skema disertai migrasi yang
diuji". Hanya `SchemaVerifier` yang benar-benar membandingkan skema hasil
migrasi, dan itu butuh snapshot per versi.

> **Wajib:** `drift_schemas/` dan `app_database.steps.dart` harus ikut
> di-commit — itu riwayat migrasi. Snapshot versi lama **harus dibuat sebelum**
> tabel diubah, selagi `schemaVersion` masih versi lama; kalau terlewat,
> skema versi itu tidak bisa direkonstruksi.

## ADR-005 — Seed memakai "kalau tabel kosong", bukan `details.wasCreated`

`beforeOpen` menyisipkan kategori default + baris `settings` ketika tabelnya
masih kosong.

**Alternatif ditolak:** `if (details.wasCreated)` (pola standar docs).

**Alasan:** device yang sudah memasang v1 tidak pernah lewat `onCreate`, jadi
tidak akan punya kategori — dan FK `products.categoryId` akan selalu gagal di
sana. Biaya: satu query count tiap app dibuka.

## ADR-006 — Tabel `settings` satu baris typed, bukan key-value

Kolom eksplisit: `storeName`, `storeAddress`, `receiptMessage`, `lastBackupAt`,
`schemaVersion`.

**Konsekuensi:** tiap field baru butuh migrasi + bump `schemaVersion`.
PIN **tidak** ada di sini (ADR-007).

**Shortcut diketahui:** `settings.schemaVersion` hanya diisi saat seed, jadi
basi setelah bump versi berikutnya. Perbarui di step migrasi saat v4 dibuat,
atau baca `PRAGMA user_version` saja kalau validasi restore (langkah 14)
membutuhkannya.

## ADR-007 — PIN: PBKDF2 bersalt, bukan SHA-256 polos

PBKDF2-HMAC-SHA256, 100.000 iterasi, salt acak 16 byte dari `Random.secure()`,
perbandingan constant-time. Format tersimpan diberi versi:
`1$iterations$salt$hash`.

**Alternatif ditolak:** `sha256.convert(utf8.encode(pin))`.

**Alasan:** PIN 6 digit hanya 10^6 kandidat. Dengan SHA-256 polos, bocornya
keystore sekali saja berarti seluruh ruang PIN bisa dicoba dalam milidetik.
Format berversi memungkinkan iterasi dinaikkan nanti tanpa mengunci pemilik
keluar — hash lama tetap bisa diverifikasi.

**Konsekuensi:** satu derivasi ~1 detik di desktop dan beberapa detik di HP,
jadi dijalankan di isolate lain lewat `compute` agar UI tidak membeku. Ini juga
sebabnya tes PIN butuh `tester.runAsync`, bukan `pumpAndSettle` saja.

## ADR-008 — `PRAGMA foreign_keys = ON` wajib ada di `beforeOpen`

**Ini bukan optimasi, ini perbaikan bug.** Tanpa pragma ini SQLite mengabaikan
**semua** `references` di `app_database.dart`: produk yang sudah dipakai
transaksi bisa terhapus permanen dan `transaction_items` jadi menggantung —
riwayat rusak, melanggar PRD. Ditemukan oleh tes, bukan oleh pembacaan kode.

Aturan penempatan:

- **Di luar `transaction()`** — pragma tidak bisa diubah dari dalam transaksi,
  dan seed berjalan di dalam transaksi.
- **Di `beforeOpen`, bukan `onUpgrade`** — `beforeOpen` jalan setelah migrasi,
  jadi migrasi tetap berjalan dengan FK mati seperti default SQLite (itu yang
  diinginkan untuk migrasi yang membangun ulang tabel).

Jangan hapus atau pindahkan tanpa membaca ADR-011.

## ADR-009 — Barcode unik lewat unique INDEX, bukan constraint kolom

`@TableIndex(name: 'products_barcode_unique', columns: {#barcode}, unique: true)`.

**Alternatif ditolak:** `text().nullable().unique()()`.

**Alasan:** SQLite tidak bisa menambah UNIQUE ke kolom lewat `ALTER TABLE`, jadi
itu memaksa migrasi yang membangun ulang tabel. `CREATE UNIQUE INDEX` cukup satu
pernyataan. Keduanya sama-sama mengizinkan banyak NULL.

**Konsekuensi:** barcode kosong dinormalkan ke NULL di repository — kalau
disimpan sebagai string kosong, produk kedua tanpa barcode akan bentrok.
Pelanggaran index diterjemahkan jadi `ValidationFailure` berpesan Indonesia,
bukan exception SQLite mentah. Migrasi v2→v3 akan **gagal** di DB yang sudah
punya barcode kembar — itu disengaja.

## ADR-010 — Kategori dibaca lewat `ProductRepository`, belum jadi fitur sendiri

`ProductRepository.watchCategories()` + `CategoryDao` disuntik ke
`ProductRepositoryImpl`.

**Alasan:** kategori baru dipakai baca-saja untuk dropdown di form produk.
Membuat `CategoryRepository` + usecase + bloc lengkap tidak dibayar oleh
kebutuhan sekarang. Pindahkan ke fitur sendiri begitu ada CRUD kategori.

## ADR-011 — Stok hanya boleh berubah lewat ledger

Aturan: **setiap** perubahan stok menulis tepat satu baris `stock_movements`
dalam transaksi yang sama.

- `updateProduct` memakai `ProductDao.updateProductDetails` yang sengaja
  mengabaikan kolom `stock`, walau entity-nya membawa nilai stok.
- Field stok di form produk read-only saat mengubah produk.
- Satu-satunya jalur: `restock()` (type `'in'`), `adjustStock()` (type
  `'adjustment'`, mencatat **selisih** bukan angka akhir), stok awal saat
  `addProduct` (type `'in'`), serta penjualan/void di `TransactionDao`.
- `deleteProduct` menghapus baris ledger produk itu lalu produknya **dalam satu
  transaksi**: ledger hanya milik produk tersebut, sementara FK dari
  `transaction_items` tetap menghalangi produk yang sudah terjual, dan rollback
  menjaga ledger tetap utuh saat gagal. Tanpa ini, produk apa pun yang punya
  stok awal jadi tidak bisa dihapus sama sekali (akibat ADR-008).

**Alternatif ditolak:** field stok tetap editable dengan auto-`adjustment`.
Ditolak karena membuat dua jalur masuk yang harus sama-sama benar, dan
memudahkan koreksi tanpa alasan tercatat.

> **Peringatan:** `decrementStock`/`incrementStock` lama di `ProductDao`
> **tidak** menulis ledger. Jangan dipakai untuk jalur penjualan — pakai
> `TransactionDao.createTransactionWithItems`.

## ADR-012 — Alur yang bolak-balik ke DB diuji di level bloc/repository

`testWidgets` berjalan di fake-async, sementara Drift memakai I/O nyata, jadi
stream-nya tidak maju dan `pumpAndSettle` habis waktu.

Pembagiannya:

- **Repository & bloc test** (`test()` biasa, async nyata): semua alur
  simpan/ubah/hapus/restok, validasi, dan reaktivitas `watch*`.
- **Widget test**: hanya yang murni UI — state kosong, penolakan validasi form.
- Plugin dipalsukan lewat platform interface resminya, bukan lewat wrapper di
  kode produksi: `FlutterSecureStoragePlatform.instance` dan
  `PathProviderPlatform.instance`.
- Layar tes dibesarkan ke 1080×2400; default 800×600 memotong form dan
  `ListView` tidak membangun widget di luar layar.

Dua jebakan yang sudah memakan waktu, jangan diulang:

- **Objek berisi stream tidak boleh dibuat di `setUp`** untuk `testWidgets`.
  `setUp` berjalan di luar zona fake-async, jadi event dari `StreamController`
  (atau Drift) yang dibuat di sana tidak pernah sampai ke dalam tes. Buat di
  dalam body tes dan daftarkan pembersihannya lewat `addTearDown`.
- **Urutan pembersihan**: tutup stream/DB dulu supaya `emit.forEach` di bloc
  selesai, baru `bloc.close()`. Terbalik membuat `bloc.close()` menggantung.

**Konsekuensi:** jalur PinGate-saat-ubah-harga, isi `StockSheet`/
`LowStockScreen`, dan **alur simpan dari form sampai layarnya tertutup** tidak
punya tes otomatis — hanya terverifikasi manual. Percobaan menutupnya dengan
repository palsu masih menggantung dan sudah dibatalkan; bug "form tidak
tertutup" (ADR-013) lolos ke tangan pemilik karena celah ini.

## ADR-013 — Hasil operasi tulis dibedakan dengan `writeCount`, bukan `status`

`ProductState.writeCount` naik setiap satu operasi tulis selesai (sukses maupun
gagal), di-emit bersama `status` dari satu tempat: `ProductBloc._emitResult`.
Layar form memakai perubahan `writeCount` sebagai penanda "simpanan saya
selesai".

**Alasan — ini perbaikan bug yang dilaporkan pemilik.** Form sebelumnya memakai
`listenWhen: previous.status != current.status`. Karena layar list sudah
berlangganan stream dan membuat `status` bernilai `success`, emisi `success`
kedua dari operasi simpan **tidak terlihat sebagai perubahan**, sehingga
`Navigator.pop` tidak pernah dipanggil dan form tidak pernah tertutup.

**Aturan:** jangan pakai `status` saja sebagai penanda selesainya satu aksi di
bloc yang juga menyiarkan state langganan stream. Kalau nanti ada bloc lain
dengan pola campuran yang sama, pakai penanda terpisah seperti ini.

**Catatan:** produk baru muncul di list lewat emisi stream **setelah**
`writeCount` naik, bukan di emisi yang sama — jadi form boleh langsung menutup
tanpa menunggu list ter-update.
