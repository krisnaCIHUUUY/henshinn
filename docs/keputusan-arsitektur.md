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

## ADR-014 — Snapshot item transaksi lengkap sejak langkah 6

`transaction_items` menyimpan `productName`, `priceAtSale`, dan
`costPriceAtSale` (migrasi v4).

**Alasan:** laba kotor (langkah 12) dihitung dari selisih dua kolom harga di
baris transaksi, bukan dari produk yang berlaku sekarang. Kalau kolom modal
ditambahkan belakangan, setiap transaksi yang sudah tercatat **permanen** tidak
punya data modal dan laporan labanya salah selamanya untuk data itu. Nama ikut
di-snapshot supaya struk lama tetap menyebut nama saat transaksi.

**Aturan:** laporan laba **tidak boleh** mengambil `costPrice` dari tabel
`products`. Selalu dari `transaction_items.costPriceAtSale`.

## ADR-015 — Total dan snapshot diambil dari DB, bukan dari UI

`TransactionDao.createSale` hanya menerima `(productId, qty)` per baris. Harga,
modal, dan nama dibaca ulang dari tabel `products` **di dalam** transaksi, dan
total dihitung di sana.

**Alasan:** entity di keranjang bisa basi (harga berubah saat keranjang masih
terbuka) atau salah. Menghitung di DB membuat satu sumber kebenaran dan
menutup celah "UI mengirim harga 1 rupiah". Ada tesnya.

## ADR-016 — Stok kurang menolak dan membatalkan seluruh penjualan

Cek stok dilakukan per baris **di dalam** `transaction()`; kalau kurang,
`InsufficientStockException` dilempar sehingga Drift me-rollback semuanya —
tidak ada header, item, pengurangan stok, maupun ledger yang tersimpan.

**Alternatif ditolak:** mengizinkan stok negatif dengan peringatan.

**Alasan:** PRD menargetkan akurasi stok ≤5%; stok negatif merusak metrik itu
dan merembet ke daftar restok serta laporan. **Konsekuensi yang harus
diterima:** kalau stok di aplikasi lebih rendah dari stok di rak, penjualan
nyata jadi terhalang sampai pemilik melakukan Koreksi Stok (ADR-011).
Keranjang menandai baris yang melebihi stok lebih awal, tapi penolakan
sebenarnya tetap di DB — UI tidak boleh jadi satu-satunya penjaga.

## ADR-017 — Scanner di-push dari kasir, bukan rute top-level

`BarcodeScannerScreen` dibuka dengan `MaterialPageRoute` +
`BlocProvider.value(value: cartBloc)` dari `CashierScreen`. Rute `/scan` yang
sempat dibuat di langkah 6 **dihapus** karena jadi mati.

**Alasan:** scan berturut berarti scanner menambah ke keranjang berkali-kali,
jadi ia butuh `CartBloc` yang sama. `CartBloc` hidup di scope `CashierScreen`,
dan rute top-level go_router dibangun di luar subtree itu — `context.read`
tidak akan menemukannya. Pola ini sama dengan cara `ProductFormScreen` dibuka
dari daftar produk.

**Konsekuensi:** scanner tidak bisa dibuka lewat deep link. Kalau nanti ada
pemanggil lain (mis. mengisi barcode di form produk), buat mode terpisah yang
mengembalikan barcode lewat `pop`, jangan paksa rute top-level memakai CartBloc.

## ADR-018 — `permission_handler` hanya untuk membuka pengaturan

`mobile_scanner` meminta izin kamera sendiri dan melaporkan penolakan lewat
`MobileScannerErrorCode.permissionDenied`. Jadi tidak ada lapisan permintaan
izin kedua.

`permission_handler` dipakai **hanya** untuk `openAppSettings()` saat izin
ditolak permanen — satu-satunya jalan pulih tanpa menginstal ulang. Jangan
tambahkan alur `Permission.camera.request()` di atas mobile_scanner: dua
peminta izin pada satu kamera membuat dialog muncul dua kali.

## ADR-019 — Barcode yang sama memakai jeda, bukan blokir permanen

Barcode identik diterima lagi setelah 1,5 detik.

**Alasan:** kode awal memblokir barcode yang sama selamanya, sehingga kasir
tidak bisa men-scan dua botol yang sama berturut-turut — qty-nya akan selalu 1.
Jeda singkat menahan pembacaan ganda dari satu barang tanpa menghalangi barang
kedua yang identik.

## ADR-020 — Layar penuh di-`push`, jangan di-`go`

Rute layar penuh (kasir, dan layar penuh berikutnya) dibuka dengan
`context.push`, bukan `context.go`.

**Alasan — ini perbaikan bug yang dilaporkan pemilik.** `context.go`
**mengganti** stack navigasi, sehingga `Navigator.canPop` bernilai false:
AppBar tidak memunculkan tombol kembali otomatis, dan tombol back fisik Android
keluar dari aplikasi alih-alih kembali ke dashboard. Layar kasir sempat benar-benar
tidak bisa ditinggalkan.

**Aturan:** pakai `go` hanya untuk perpindahan tab di `StatefulShellRoute`.
Layar yang ditumpuk di atasnya memakai `push`, dan sediakan `leading` eksplisit
kalau tombol otomatisnya tidak muncul.

**Catatan:** keranjang hanya hidup di memori, jadi keluar dari kasir
menghapusnya. `PopScope` dengan `canPop: cart.items.isEmpty` membuat tombol
AppBar dan back fisik sama-sama lewat satu konfirmasi. Konsekuensi lain dari
`push`: dashboard tetap hidup di belakang kasir dan tidak dilepas selama
transaksi berjalan.

## ADR-021 — `ReceiptFormatter` adalah satu-satunya tata letak struk

`Receipt` (data) dan `ReceiptFormatter` (tata letak 32 karakter) dipisah.
Formatter menghasilkan `List<String>`; preview, PDF, dan nanti byte ESC/POS
semuanya merender daftar baris yang sama.

**Alasan:** PRD §2.8 mewajibkan satu model untuk tiga keluaran. Kalau tiap
keluaran menata sendiri, struk di layar akan berbeda dengan yang tercetak dan
bug tata letak harus diperbaiki tiga kali.

**Aturan:** jangan pernah menyusun teks struk di layar atau di service
printer. Tambah/ubah tata letak hanya di `ReceiptFormatter`, dan tesnya
menjaga tidak ada baris yang melebihi lebar kertas.

## ADR-022 — Struk dibangun dari snapshot, dan hanya setelah transaksi tersimpan

`buildReceipt(transactionId)` membaca `transactions` + `transaction_items`,
bukan keranjang. Layar struk selalu dibuka **setelah** penjualan tersimpan.

**Alasan:** US-1.4 mewajibkan transaksi tetap tersimpan walau cetak gagal.
Karena struk dibangun dari data yang sudah ada di DB, tidak ada jalur di mana
kegagalan cetak bisa membatalkan penjualan — `PrinterService` sama sekali tidak
menyentuh database. Nilai item juga dari snapshot, jadi cetak ulang struk lama
identik dengan aslinya (US-3.4).

## ADR-023 — Plugin printer: `esc_pos_bluetooth` ditolak

Pemeriksaan pub.dev yang PRD §4 minta ("periksa status maintenance tiap plugin
sebelum dikunci"):

| Paket | Versi | Rilis terakhir |
|---|---|---|
| `esc_pos_bluetooth` (disebut rencana) | 0.4.1 | **2021-10-06** |
| `esc_pos_utils` | 1.1.0 | 2021-09-21 |
| `blue_thermal_printer` | 1.2.3 | 2022-07-19 |
| `print_bluetooth_thermal` | 1.2.5 | 2026-09-28 |
| `flutter_thermal_printer` | 2.3.0 | 2026-09-10 |
| `esc_pos_utils_plus` | 2.0.4 | 2024-09-01 |

**Keputusan:** saat printer tiba, pakai **`print_bluetooth_thermal`** untuk
transport Bluetooth + **`esc_pos_utils_plus`** untuk membuat byte ESC/POS.
Jangan pakai `esc_pos_bluetooth`/`esc_pos_utils`: ditinggalkan sejak 2021 dan
mendahului model izin Bluetooth Android 12+.

Keduanya **belum ditambahkan ke pubspec** — dependency yang belum dipakai
hanya menambah risiko build. Tambahkan saat impl-nya ditulis.

## ADR-024 — Impl Bluetooth ditunda sampai printer ada

Langkah 9 berhenti di `PrinterService` + `PdfPrinterService`. Impl ESC/POS
Bluetooth belum ditulis.

**Alasan:** PRD §2.8 memang meresepkan ini ("selama printer belum ada,
pengembangan memakai preview dan PDF, logika cetak di balik interface
`PrinterService`"), §3.4 merencanakan spike 1 hari saat printer tiba, dan §3.2
menetapkan PDF/share sebagai garis potong yang sah. Menulis ratusan baris
Bluetooth yang tidak bisa dijalankan — izin Android 12+, pairing, retry,
perilaku beda per merk 58mm — berarti kode yang pasti harus ditulis ulang
setelah bertemu printer sungguhan.

**Saat printer tiba:** tambahkan `EscPosPrinterService` yang mengirim keluaran
`ReceiptFormatter` sebagai byte, lalu tukar satu baris registrasi
`PrinterService` di `injection_container.dart`. Tidak ada pemanggil yang perlu
berubah.

## ADR-025 — Pemuatan async di `initState` wajib ber-try/catch

Setiap layar yang memuat data di `initState` harus membungkusnya dengan
try/catch dan mematikan flag loading-nya di `catch`, bukan hanya menangani
`Left` dari `Either`.

**Alasan — ini perbaikan bug yang dilaporkan pemilik.** `StoreInfoScreen`
macet di spinner selamanya: `sl<SettingsRepository>()` melempar (DI stale),
exception-nya lolos dari `_load()`, `_loading` tidak pernah dimatikan, dan
tidak ada pesan maupun jalan keluar. Menangani `Left` saja tidak cukup —
`Left` hanya muncul kalau repository-nya **sempat dipanggil**.

Pola yang sama ada di `ReceiptPreviewScreen` dan `SettingScreen`; ketiganya
sudah diperbaiki.

**Aturan:** `_loading = false` (atau penanda error) harus terjadi di **semua**
jalur keluar. Layar yang bisa gagal total menampilkan pesan + tombol "Coba
lagi"; layar yang masih berguna tanpa data itu kembali ke nilai default dan
tidak melempar.

**Catatan terkait — gejala "build stale" sudah tiga kali menyesatkan.**
Aturannya:

| Yang diubah | Yang dibutuhkan | Gejala kalau salah |
|---|---|---|
| Kode Dart biasa | hot reload (`r`) | — |
| Registrasi DI (`initDependencies`) | hot **restart** (`R`) | `GetIt: ... is not registered`, atau `NoSuchMethodError` dari konstruktor |
| Menambah/menghapus package di `pubspec.yaml` | **`flutter run` dari nol** | `MissingPluginException(No implementation found for method X on channel Y)` |

`initDependencies()` hanya jalan di `main()`, dan hot restart tidak mengompilasi
ulang sisi native — plugin baru butuh build penuh. Sebelum menduga ada bug,
bandingkan waktu build APK dengan waktu `pubspec.yaml` diubah.

## ADR-026 — Direktori sementara selalu dari `path_provider`

File sementara (PDF struk, dan nanti file backup) ditulis ke
`getTemporaryDirectory()` dari `path_provider`, **bukan**
`Directory.systemTemp`.

**Alasan — ini perbaikan bug yang dilaporkan pemilik.** `Directory.systemTemp`
di Android menunjuk `/tmp` yang tidak ada dan tidak bisa ditulis aplikasi,
sehingga "Bagikan PDF" selalu gagal di HP. Tes di desktop **lolos** karena di
Windows/Linux `systemTemp` memang valid — jadi tesnya memberi rasa aman yang
palsu. Pelajarannya: API dart:io yang bergantung pada lingkungan OS tidak
terbukti oleh tes desktop.

**Aturan:** jangan pakai `Directory.systemTemp` di kode produksi. Di tes,
suntik direktorinya lewat parameter (seperti `PdfPrinterService.outputDirectory`)
supaya default produksinya tidak ikut diuji dengan jalur yang salah.

## ADR-027 — Teks struk dibatasi Latin-1 di keluaran PDF

`PdfPrinterService` memetakan karakter di atas U+00FF menjadi `?` sebelum
dirender.

**Alasan:** font Courier bawaan PDF hanya mendukung Latin-1 (dart_pdf
memperingatkan "Courier has no Unicode support"). Nama produk dengan karakter
di luar itu bisa tergambar kosong atau menggagalkan pembuatan dokumen, dan
gejalanya muncul ke pemilik sebagai "gagal membagikan".

**shortcut:** kalau nanti katalog memakai karakter non-Latin, ganti dengan font
monospace Unicode sebagai aset — jangan hapus pemetaan ini tanpa menggantinya.
Pembatasan ini **hanya** di keluaran PDF; `ReceiptFormatter` tetap menghasilkan
teks asli untuk preview dan salin-teks.
