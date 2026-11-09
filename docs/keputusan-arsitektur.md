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

## ADR-028 — Layar baca memanggil repository langsung, bukan Bloc baru

Riwayat (list reaktif) dan detail transaksi memakai `StreamBuilder` +
`sl<TransactionRepository>()`, **tanpa** `HistoryBloc`.

**Alasan:** keputusan ini ditanyakan ke pemilik repo di langkah 10 dan dipilih
secara eksplisit. Layar ini hanya membaca satu stream dan memicu satu aksi
(void); `HistoryBloc` penuh berarti `history_event.dart` +
`history_state.dart` + Freezed + codegen untuk nilai yang sama. Layar baca lain
sudah berpola begini (`StoreInfoScreen`, `ReceiptPreviewScreen`,
`SettingScreen`).

**Konsekuensi yang harus diterima:** ini menyimpang dari AGENTS.md §3 ("list
reaktif pakai `watch*` + `emit.forEach`"). Batasnya: Bloc tetap wajib begitu
layar punya state yang perlu diuji sendiri (form, keranjang, PIN). Tes untuk
layar baca adalah **tes repository**, bukan tes bloc.

Stream disimpan di field state, bukan dibuat di `build()` — stream baru setiap
build berarti berlangganan ulang dan list berkedip ke spinner.

## ADR-029 — Void menolak transaksi yang sudah void

`TransactionDao.voidTransaction` membaca header di dalam transaksi dan melempar
`StateError` kalau statusnya sudah `voided`.

**Alasan:** void mengembalikan stok. Tanpa penjaga ini, dua kali void
mengembalikan stok dua kali dan angkanya salah **permanen** — tidak ada jejak
yang bisa dipakai membedakan mana yang benar. Pengecekan harus di dalam
`transaction()` yang sama dengan penulisannya, bukan di UI atau repository:
dua tekan tombol cepat bisa lolos dari pengecekan di layar.

Alasan void divalidasi dua kali: tombol di dialog mati selama kolom kosong,
**dan** repository menolak alasan yang hanya spasi. Yang kedua yang mengikat,
karena syaratnya datang dari audit pemilik (PRD §2.4), bukan dari UI.

## ADR-030 — Riwayat diurutkan `date DESC, id DESC`

**Alasan:** kolom `date` beresolusi detik. Dua transaksi di detik yang sama
(wajar di warung saat ramai) muncul dengan urutan yang ditentukan rencana query
SQLite, bukan oleh waktu — terlihat sebagai "urutan riwayat kadang terbalik".
`id` monoton naik, jadi dia pemecah seri yang benar. Bug ini ketangkap tes,
bukan oleh pembacaan kode.

Jumlah item per transaksi dihitung dengan satu query join + `groupBy` +
`qty.sum()` (`useColumns: false`), bukan N query per baris list.

## ADR-031 — Laba kotor tampil terbuka, tanpa PIN

Omzet, laba kotor, dan jumlah transaksi tampil langsung di dashboard. PIN
tetap melindungi void, restore backup, dan ubah harga/modal.

**Alasan:** PRD §1.6 menulis "PIN melindungi ... layar laba", tapi menandainya
**asumsi yang perlu dikonfirmasi pemilik**. Pemilik repo ditanya di langkah 12
dan memilih laba terbuka. Dasarnya metrik PRD §3.2 sendiri: "laba dan produk
terlaris hari ini terlihat ≤ 10 detik dan ≤ 2 tap" — PIN 6 digit setiap kali
melanggar metrik itu.

**Konsekuensi:** siapa pun yang memegang HP saat aplikasi terbuka bisa melihat
margin. Ini diterima karena satu HP = satu pemilik (PRD §1.4: tanpa multi-user).
Kalau nanti ada kasir lain yang tidak boleh tahu modal, yang berubah **bukan**
dashboard-nya saja — asumsi "satu PIN, satu pemegang" harus dibuka ulang.

## ADR-032 — Pengelompokan per hari dihitung di Dart, bukan dengan strftime

Omzet per hari dikelompokkan di Dart dari header transaksi, bukan dengan
`strftime`/`date` SQLite.

**Alasan:** drift menyimpan `DateTime` sebagai unix epoch **UTC**. Fungsi
tanggal SQLite akan memotong hari di 00:00 UTC = **07:00 WIB**, jadi penjualan
dini hari masuk ke hari sebelumnya dan angka harian salah tanpa pernah terlihat
salah jumlahnya — totalnya tetap benar, hanya pembagian harinya melenceng.
Batas hari di aplikasi ini selalu tengah malam **lokal** (lihat juga
`ReportPeriod.rangeFrom`).

**Batas yang diterima:** ini berarti header transaksi satu periode dibaca ke
memori. Aman untuk satu warung; kalau nanti datanya tahunan, pindahkan ke
agregat SQL **dengan offset zona waktu eksplisit**, jangan ke `strftime` apa
adanya.

Agregat lain (laba, item terjual, produk terlaris) tetap di SQL karena tidak
bergantung pada batas hari.

## ADR-033 — fl_chart dipakai untuk tooltip, bukan untuk tampilan

Grafik omzet 7 hari di dashboard memakai `BarChart` dari `fl_chart` (sudah ada
di `pubspec.yaml`), menggantikan batang `Container` buatan sendiri.

**Alasan:** batang buatan sendiri hanya bisa dibandingkan tingginya. Yang
dibutuhkan pemilik adalah angka per hari, dan itu datang dari
`BarTouchTooltipData` — ketuk batang, muncul rupiah hari itu. Kalau tidak ada
kebutuhan itu, batang `Container` sudah cukup dan paketnya tidak perlu.

**Catatan API:** fl_chart v1 memakai `SideTitleWidget(meta: meta)`; contoh lama
dengan `axisSide:` tidak lagi berlaku. `maxY` dipaksa 1 kalau seluruh periode
nol, karena rentang nol membuat chart kosong.

Laporan 7/30 hari sengaja **tanpa** grafik: 30 batang tidak terbaca di layar HP,
dan agregat periodenya sudah menjawab pertanyaannya.

## ADR-034 — File backup hanya lewat cache aplikasi + share sheet

**Keputusan.** Export backup menulis file ke `getTemporaryDirectory()` (cache
aplikasi) lalu langsung membuka share sheet. Tidak ada salinan di folder yang
bisa dibuka file manager, dan tidak ada permintaan izin storage.

**Alasan.** Sejak Android 11 (scoped storage) menulis ke penyimpanan bersama
butuh SAF atau MediaStore — satu alur izin dan file picker tersendiri, padahal
PRD §1.6 hanya menuntut backup bisa dikirim ke Drive/WhatsApp, yang justru
pekerjaan share sheet. Pilihan ini ditawarkan ke pemilik repo bersama opsi
"simpan juga di folder yang kelihatan", dan opsi cache + share dipilih.

**Konsekuensi yang diterima.** File di cache boleh dihapus OS kapan saja, jadi
backup hanya benar-benar ada kalau user memilih tujuan di share sheet. Tidak
ada daftar backup di dalam aplikasi, dan tidak ada cara mengambil ulang file
yang sudah dibuang OS. Kalau nanti dibutuhkan folder yang kelihatan, itu
pekerjaan SAF — jangan ditambal dengan `permission_handler` + path keras, yang
tidak jalan di Android modern.

## ADR-035 — `lastBackupAt` dicatat kecuali share sheet dibatalkan

**Keputusan.** `exportAndShare` mencatat `lastBackupAt` setelah share sheet
tertutup, **kecuali** statusnya `ShareResultStatus.dismissed`. Status
`unavailable` tetap dihitung berhasil.

**Alasan.** Di Android `share_plus` sering tidak bisa membedakan "dibagikan"
dari "sheet ditutup" dan mengembalikan `unavailable` — hal yang sama sudah
menggigit di layar struk (lihat catatan `receipt_preview_screen.dart`). Kalau
`unavailable` ditolak, `lastBackupAt` tidak akan pernah terisi di HP mana pun
dan pengingat 7 hari jadi banner permanen yang diabaikan orang.

**Konsekuensi yang diterima.** `lastBackupAt` bisa berbohong: user membuka
share sheet, memilih aplikasi, lalu membatalkan di aplikasi tujuan, dan aplikasi
tetap mengira backup berhasil. Ini ditukar sadar dengan pengingat yang bisa
dimatikan. Jangan jadikan `lastBackupAt` bukti bahwa file-nya ada — satu-satunya
bukti adalah restore (langkah 14). Menyatu dengan ADR-034: file di cache juga
bisa hilang tanpa jejak.

## ADR-036 — Ambang pengingat backup dihitung per hari kalender

**Keputusan.** `StoreInfo.backupIsStale(now)` membandingkan tanggal (tengah
malam ke tengah malam), bukan selisih jam, dan `lastBackupAt == null` dianggap
basi. Ambangnya `> 7` hari.

**Alasan.** Dengan selisih jam, backup jam 23:00 yang dibuka jam 01:00 tujuh
hari kemudian masih terhitung 7 hari lewat `inDays` dan banner tertunda hampir
sehari penuh. Hari kalender juga sudah jadi konvensi proyek ini untuk
pengelompokan tanggal (ADR-032), karena drift menyimpan epoch UTC. "Belum pernah
backup" diperlakukan basi karena itu kondisi paling berbahaya, bukan netral —
HP baru tanpa backup adalah justru saat pengingatnya paling perlu muncul.

**Konsekuensi yang diterima.** `> 7` berarti banner muncul di hari ke-8, bukan
ke-7; angka ini diambil harfiah dari `docs/implementasi.md` langkah 13 ("jika >7
hari"). Kalau yang dimaksud hari ke-7, ubah `backupStaleAfterDays` — jangan
ubah cara hitungnya ke selisih jam.

## ADR-037 — Export backup tidak di-PIN

**Keputusan.** Membuat dan membagikan backup tidak memerlukan PIN. Restore
(langkah 14) tetap wajib PIN.

**Alasan.** PRD §2.7 menyebut PIN untuk void, restore, dan ubah harga/modal —
export tidak termasuk. Konsisten dengan ADR-031 yang sudah memutuskan "satu PIN,
satu pemegang": PIN di aplikasi ini melindungi dari kesalahan kasir yang merusak
data, bukan dari pemilik membaca datanya sendiri. Pilihan ini dikonfirmasi ke
pemilik repo sebelum ditulis.

**Konsekuensi yang diterima.** Siapa pun yang memegang HP dalam keadaan terbuka
bisa mengirim seluruh data penjualan ke luar. Itu asumsi "satu HP, satu
pemegang" yang sama seperti ADR-031; kalau asumsi itu gugur (kasir pegawai,
HP dipakai bergantian), yang harus dibuka ulang bukan baris ini saja tapi
seluruh model PIN — lihat ADR-031.

---

## ADR-038 — Kategori dibuat dari form produk, tanpa hapus dan tanpa unique index

**Keputusan.** Kategori adalah **alat cari cepat** di daftar produk, bukan data
laporan: tidak muncul di struk dan tidak dipakai perhitungan apa pun. Karena itu
empat hal sekaligus:

1. **Dibuat dari form produk**, bukan layar pengelola kategori. Dropdown
   kategori punya opsi `+ Kategori baru`; namanya diketik di situ dan
   kategorinya dibuat saat produk disimpan.
2. **Tidak ada hapus dan tidak ada ganti nama.** Gantinya, tab kategori hanya
   tampil untuk kategori yang punya minimal satu produk **aktif**
   (`categoriesWithActiveProducts` di `product_list_screen.dart`).
3. **Nama dicocokkan tanpa peka huruf besar/kecil** sebelum insert
   (`CategoryDao.findCategoryByName`). "minuman" saat "Minuman" sudah ada masuk
   ke kategori lama, tanpa pesan error.
4. **Tanpa unique index di DB.** Jaminan nama tunggal ada di kode saja.

**Alasan.** PRD §F2 menyebut kategori sebagai *kolom produk*, bukan entitas yang
dikelola — jadi layar CRUD kategori adalah fitur yang tidak pernah diminta, dan
`CategoryDao.updateCategory`/`deleteCategory` yang ada sejak langkah 2 memang
tidak pernah dipanggil dari mana pun (keduanya dihapus di pekerjaan ini, bukan
ditinggal sebagai kode mati). Menyembunyikan tab kosong menyelesaikan masalah
salah ketik tanpa menambah satu pun tombol: kategori salah ketik lenyap begitu
produknya dipindah. Dan unique index berarti bump `schemaVersion`, yang akan
menambah satu variabel baru ke uji restore langkah 14 (ADR-041) demi masalah
yang tidak ada di "satu HP, satu pemakai".

**Konsekuensi yang diterima.**

- **Tab 'Umum' akan hilang sendiri** begitu semua produk punya kategori nyata.
  Itu benar menurut aturan di atas, tapi akan terasa seperti kerusakan kalau
  tidak diharapkan. Barisnya tetap ada di DB dan tetap jadi tujuan FK
  `products.categoryId` hasil seed langkah 2 — yang hilang hanya tabnya.
- **Baris kategori menumpuk tanpa bisa dibersihkan dari dalam aplikasi.** Salah
  ketik hilang dari layar, tidak dari DB. Diterima: satu baris berisi satu nama
  pendek, dan tidak ada laporan yang membacanya.
- **Kategori bisa lahir tanpa produk.** Kalau penyimpanan produk gagal setelah
  kategorinya dibuat, kategori itu tetap ada. Tidak dibungkus satu transaksi
  karena akibatnya nol: tab kosong tidak pernah ditampilkan.
- **`lower()` SQLite hanya melipat ASCII**, jadi "Café" dan "café" masih bisa
  jadi dua kategori. Ditandai `shortcut:` di `CategoryDao`.
- **Nilai dropdown `-1`** (`_newCategoryOption`) adalah penanda opsi, bukan id.
  Aman karena id Drift selalu positif, tapi jangan pernah dikirim ke DB —
  `_resolveCategoryId` wajib menukarnya dengan id asli lebih dulu.
- Filter tabnya **fungsi lepas, bukan kode di dalam `build`**, semata-mata
  supaya bisa diuji: di `testWidgets` stream Drift tidak pernah maju, jadi tes
  widget berbasis DB untuk aturan ini mustahil (ADR-012 — dicoba dan gagal
  justru begitu, bukan diasumsikan).

Membatalkan keputusan ini (misal kategori jadi dimensi laporan) berarti
mengubah aturan 2 lebih dulu: begitu laporan lama memakai nama kategori,
menyembunyikan tab tidak lagi cukup dan hapus/ganti nama jadi wajib ada.

---

## ADR-039 — Restore menutup aplikasi, bukan membangun ulang DI

**Keputusan.** Setelah restore berhasil, `RestoreAction` menampilkan dialog yang
tidak bisa dilewati lalu memanggil **`exit(0)`**. Aplikasi tidak mencoba
memulihkan dirinya di dalam proses yang sama.

**Alasan.** Semua DAO, repository, dan bloc di `injection_container.dart`
terdaftar sebagai `registerLazySingleton` yang bergantung pada satu
`AppDatabase`. Restore menutup koneksi itu dan menukar file di bawahnya, jadi
begitu `restoreFrom` mengembalikan `Right`, setiap singleton yang sudah pernah
dibuat memegang pegangan mati. Alternatif `sl.reset()` + `initDependencies()` +
remount seluruh widget tree ditolak: bloc yang dipasang di root (`CartBloc`,
`ProductBloc`) bisa tertinggal memegang koneksi lama, dan kegagalannya muncul
sebagai layar kosong atau error acak beberapa menit kemudian — kelas bug paling
sulit dilacak, justru di saat data pemilik paling rawan. Restore adalah aksi
sekali setahun; kehalusannya tidak sebanding dengan risikonya.

**Harus `exit(0)`, bukan `SystemNavigator.pop()`.** Versi pertama memakai
`SystemNavigator.pop()` dan lolos semua tes, tapi gagal di HP: layar putih
kosong saat aplikasi dibuka lagi. Sebabnya `SystemNavigator.pop()` hanya
menutup Activity dan membiarkan prosesnya hidup — jadi `main()` tidak jalan
ulang, `initDependencies()` tidak jalan ulang, dan get_it masih memegang
`AppDatabase` yang baru saja ditutup oleh restore. Setiap query lewat pegangan
mati itu dan tidak ada yang pernah terender. Membuang aplikasi dari Recents
lalu membukanya kembali menampilkan data yang sudah dipulihkan dengan benar,
yang membuktikan filenya sehat dan masalahnya murni daur hidup proses. Ini
kelas bug yang sama dengan ADR-025: **tidak ada tes Dart yang bisa
menangkapnya**, karena tes selalu berjalan di proses baru. Kalau suatu saat
`exit(0)` diganti — misalnya karena lint melarangnya — penggantinya wajib
benar-benar mematikan proses, bukan sekadar menutup layar.

**Konsekuensi yang diterima.** Pemilik harus membuka aplikasi lagi secara
manual, dan itu terasa kasar. `exit(0)` juga melewati daur hidup Android:
boleh di sini karena koneksi database sudah ditutup lebih dulu, jadi tidak ada
yang perlu di-flush — jangan dijadikan pola untuk tombol keluar lain. Kalau suatu saat restore jadi sering (mis. pindah
HP berkali-kali saat pelatihan), yang harus dibuka ulang bukan dialognya tapi
cara `AppDatabase` didaftarkan — misalnya membungkusnya di belakang satu
pemegang koneksi yang bisa ditukar, bukan singleton langsung.

---

## ADR-040 — Salinan pengaman restore hanya satu file di cache

**Keputusan.** Sebelum menimpa database aktif, `restoreFrom` menulis
`henshin-sebelum-restore.sqlite` ke cache aplikasi lewat `exportInto`
(`VACUUM INTO`), selalu di jalur yang sama dan selalu menimpa yang lama. Tidak
ada riwayat, tidak ada layar untuk melihat atau memilihnya.

**Alasan.** Tujuannya satu: membatalkan satu restore yang baru saja salah.
Lewat `VACUUM INTO`, bukan menyalin file mentah, supaya salinannya konsisten
dengan alasan yang sama seperti ADR-034. Menyimpannya bertumpuk per tanggal di
`getApplicationSupportDirectory` ditolak: tumbuh tanpa batas di penyimpanan
internal dan butuh kode pembersih, padahal tidak ada UI yang pernah
menampilkannya. Pilihan ini dikonfirmasi ke pemilik repo sebelum ditulis.

**Konsekuensi yang diterima.** Android boleh menghapus cache kapan pun, jadi
file ini **bukan backup** dan tidak boleh disebut begitu ke pemilik. Dan karena
tidak ada tombol pemulihnya, memakainya butuh ADB atau bantuan developer —
utang yang sudah dicatat di `docs/progress.md`. Kalau salinan pengaman ini
pernah benar-benar dibutuhkan dan ternyata sudah dibuang OS, yang salah bukan
kodenya tapi keputusan ini.

---

## ADR-041 — Validasi backup membaca `user_version`, dan menerima skema lebih tua

**Keputusan.** `BackupRepositoryImpl.validate` menolak file yang bukan SQLite,
yang tidak punya keenam tabel `@DriftDatabase`, atau yang `PRAGMA user_version`
nya 0 atau lebih besar dari `schemaVersion` aplikasi. Skema yang lebih tua
diterima. File kandidat dibuka dengan `package:sqlite3` secara `readOnly`,
**tidak pernah** sebagai `AppDatabase`.

**Alasan.** Tiga hal yang mudah salah, masing-masing punya alasannya:
(1) Membuka kandidat sebagai `AppDatabase` akan menjalankan
`migration.onUpgrade` dan **mengubah file backup milik pemilik** sebelum ia
menyetujui apa pun — karena itu validasinya memakai sqlite mentah.
(2) Versi dibaca dari `user_version` yang dinaikkan Drift sendiri, bukan kolom
`settings.schemaVersion` yang hanya diisi saat seed dan sudah ditandai
`shortcut:` sebagai basi di `app_database.dart`. Memakai kolom itu berarti
menolak backup yang sebenarnya sah.
(3) Skema lebih tua diterima karena migrasi akan menaikkannya sendiri saat file
dibuka ulang — hampir tanpa kode tambahan. Menolaknya akan membuat setiap
backup yang dibuat sebelum update aplikasi jadi sampah permanen, padahal backup
lama justru yang paling dibutuhkan saat HP hilang. Pilihan ini dikonfirmasi ke
pemilik repo sebelum ditulis.

**Konsekuensi yang diterima.** Validasi hanya memeriksa **nama** tabel, bukan
kolomnya. File SQLite yang kebetulan punya enam tabel bernama sama akan lolos
validasi dan baru gagal saat dibuka Drift — setelah data aktif tertimpa. Yang
menyelamatkan keadaan itu adalah salinan pengaman ADR-040, bukan validasinya.
Memperketatnya berarti menyalin daftar kolom ke dalam kode validasi dan
memeliharanya setiap kali skema berubah; itu sengaja tidak dilakukan karena
skenario "database asing dengan enam nama tabel yang persis sama" tidak
realistis di HP pemilik warung.

---

## ADR-042 — Crash-free rate tidak diukur; keandalan dijaga uji manual

**Keputusan.** Metrik PRD §1.5 "crash-free ≥99%" tidak diukur sebagai angka.
Keandalan dinilai dari uji manual pemilik (langkah 15) dan dari suite tes, dan
`docs/progress.md` menyebutnya "tidak terukur", bukan "tercapai".

**Alasan.** Menghitung crash-free rate butuh menghitung sesi dan crash lalu
mengirimkannya ke suatu tempat — artinya SDK crash reporting dan jaringan.
Aplikasi ini tidak punya backend sama sekali dan "cloud sync / auto cloud
backup" ada di daftar out-of-scope (AGENTS.md §6 / PRD §1.4), jadi
menambahkannya bukan sekadar satu dependency: ia membatalkan sifat
offline-only yang jadi alasan produk ini ada. Menyimpan hitungan crash secara
lokal juga ditolak — crash justru sering terjadi sebelum sesuatu bisa ditulis
ke disk, dan tidak ada yang akan pernah membacanya.

**Konsekuensi yang diterima.** Angka itu akan tetap kosong di PRD selamanya,
dan ini harus dikatakan apa adanya ke pemilik, bukan dianggap lolos karena
"tidak ada yang terlihat crash". Yang menggantikannya lebih lemah: 155 tes dan
satu sesi uji manual oleh satu orang di satu HP. Kalau suatu saat Henshin
dipakai lebih dari satu warung, yang harus dibuka ulang bukan baris ini tapi
asumsi "satu HP, satu pemegang" (ADR-031) — dan saat itu crash reporting
mungkin layak dipertimbangkan ulang bersama keputusan offline-only-nya.

---

## ADR-043 — Halaman scan dikunci potrait, frame diperlebar sebagai gantinya

**Keputusan.** `BarcodeScannerScreen` mengunci `DeviceOrientation.portraitUp`
di `initState` dan membuang preferensi itu (`setPreferredOrientations(const [])`)
di `dispose`. Frame pemandu diubah jadi lebar-dan-pendek (0,85 × lebar layar,
tinggi 0,55 × lebar frame), tidak lagi mengikuti bentuk layar. Area deteksi
tetap seluruh frame kamera — `scanWindow` **tidak** dipakai.

**Alasan.** Keputusan lama adalah landscape, dengan alasan yang hanya hidup di
satu komentar: barcode 1D berupa garis vertikal, jadi lebih mudah masuk frame
kalau framenya lebar. Alasan itu benar secara optik tapi mengabaikan cara
alatnya dipakai — kasir memegang HP dengan satu tangan sementara tangan lain
memegang barang, dan memutar HP ke landscape di tengah transaksi memakan waktu
yang justru dihitung metrik PRD §1.5 (3 item ≤30 detik). Pemilik meminta
potrait. Keuntungan optik landscape diganti dengan melebarkan frame pemandunya:
bentuk frame, bukan orientasi layar, yang menuntun kasir mengarahkan kamera.

**`scanWindow` ditolak.** `mobile_scanner` bisa membatasi deteksi ke satu
persegi lewat `scanWindow`, dan sekilas itu cocok dengan frame pemandu. Ditolak
karena akibatnya berlawanan dengan tujuannya: hari ini deteksi berjalan di
seluruh gambar kamera dan framenya murni pemandu, jadi barcode yang sedikit di
luar frame tetap terbaca. Membatasi deteksi ke frame yang di potrait justru
lebih kecil akan membuat scan **lebih sulit** dari sekarang. Framenya sengaja
dibiarkan "berbohong sedikit" ke arah yang memaafkan, bukan yang menghukum.

**Konsekuensi yang diterima.** Barcode 1D yang sangat panjang (EAN-13 pada
kemasan besar) mungkin perlu kamera ditarik lebih jauh di potrait dibanding
landscape, dan itu bisa menurunkan ketajaman. Belum terukur — metrik PRD
"produk masuk keranjang ≤2 detik" belum pernah diukur dengan stopwatch bahkan
sebelum perubahan ini, jadi tidak ada angka pembanding. Kalau di lapangan
ternyata barcode panjang jadi sering gagal, yang dibuka ulang bukan orientasinya
(pemilik sudah memutuskan) tapi frame dan zoom-nya — `MobileScannerController`
punya kontrol zoom yang sampai sekarang tidak dipakai sama sekali.

**Catatan.** `dispose` versi lama mengunci potrait alih-alih membuang
preferensinya. Karena tidak ada layar lain yang menyentuh `SystemChrome`,
efeknya seluruh aplikasi terkunci potrait setelah scanner dibuka sekali —
tidak pernah terlihat karena aplikasinya memang dipakai potrait. Sekarang
dibuang dengan daftar kosong supaya layar ini tidak menetapkan kebijakan untuk
layar lain.

---

## ADR-044 — Kunci pencarian barcode dinormalkan sama di tulis dan baca; pencocokan longgar ditolak

**Keputusan.** `ProductRepositoryImpl.getProductByBarcode` memangkas kode yang
masuk (`trim`) dan mengembalikan `Right(null)` untuk kode kosong, persis
senormal jalur simpan (`_blankToNull`). Pencocokan di DAO tetap **persis**
(`barcode.equals`) — tidak ada toleransi nol di depan, tidak ada `LIKE`.

**Alasan.** Bug nyata yang dilaporkan pemilik 2026-11-08: produk yang
barcodenya sudah terdaftar tidak ketemu saat di-scan. Dekodenya sehat; yang
rusak adalah kesepakatan soal kunci. Barcode disimpan sudah dipangkas, tapi
kode dari scanner dicari apa adanya, dan `equals` tidak memaafkan satu karakter
pun. Beberapa simbologi 1D (Code 39) mengembalikan `rawValue` dengan karakter
penutup. **Aturannya: kalau satu nilai dinormalkan sebelum disimpan, ia wajib
dinormalkan dengan cara yang sama sebelum dicari.** Asimetri seperti ini tidak
akan tertangkap tes yang memakai string yang sama di kedua sisi — tes lama
melakukan itu dan lolos selama berbulan-bulan.

**Pencocokan longgar ditolak.** Kemasan UPC-A mencetak 12 digit sementara
scanner bisa melaporkannya sebagai EAN-13 dengan nol tambahan di depan, jadi
mencoba kedua bentuk terlihat menggoda. Ditolak: dua produk berbeda yang
barcodenya hanya beda nol di depan akan saling tertukar, dan di kasir itu
berarti barang salah masuk keranjang dan harga salah tercetak di struk —
kegagalan yang lebih buruk daripada "barcode belum terdaftar", karena yang
pertama tidak kelihatan. Kalau nanti ini benar-benar jadi masalah di lapangan,
yang benar bukan pencocokan longgar tapi menormalkan ke satu bentuk kanonik
(mis. selalu 13 digit) **di kedua jalur sekaligus**, dan index uniknya harus
ikut memakai bentuk itu.

**Konsekuensi yang diterima.** Perbedaan karakter yang sebenarnya pada bug ini
tidak pernah tercatat — perbaikannya terbukti bekerja di HP pemilik, tapi dua
string yang dibandingkan tidak pernah diambil. Jadi tidak ada bukti bahwa
`trim` yang menyelesaikannya, hanya bukti bahwa sesudahnya berhasil. Kalau
gejala serupa muncul lagi, mulai dari mengambil kedua string itu, jangan
menganggap ADR ini sudah menjelaskannya.

**Terkait.** Cacat yang menyembunyikan bug ini bukan di sini tapi di
presentation: `_onDetect` melipat `Left(DatabaseFailure)` dan `Right(null)`
menjadi satu lewat `getOrElse(() => null)`, sehingga setiap error database
muncul sebagai "Barcode belum terdaftar". Pola itu — `getOrElse` pada
`Either<Failure, T?>` di mana `null` juga punya arti sendiri — patut dicurigai
di mana pun ia muncul: ia membuang satu-satunya informasi yang membedakan
"tidak ada" dari "gagal".

---

## ADR-045 — Produk yang pernah terjual terkunci selamanya, dan pesan gagal tidak boleh menebak penyebab

**Keputusan.** Produk yang punya baris `transaction_items` tidak bisa dihapus,
dan **void tidak membebaskannya**. Pesan penolakannya menyebut nama produk,
alasannya, dan hanya menyarankan "nonaktifkan" kalau produk itu memang masih
aktif. Blok `catch` di `ProductRepositoryImpl.deleteProduct` hanya memetakan
pelanggaran FK ke pesan itu; exception lain di-`rethrow` dan tampil sebagai
dirinya sendiri.

**Alasan.** Dua hal terpisah yang ketemu lewat satu laporan pemilik
(2026-11-08: "produk tidak aktif gagal terhapus, yang tampil malah popup produk
masih aktif").

1. **Penolakannya benar, pesannya salah.** Jalur hapus tidak pernah membaca
   `isActive`; yang mengunci adalah riwayat penjualan. Pesan lama menyuruh
   menonaktifkan produk yang sudah dinonaktifkan, sehingga terbaca seolah
   aplikasi mengira produk itu masih aktif. Pemilik menyimpulkan ada bug di
   tempat yang tidak ada bugnya.
2. **`catch` lama melabeli SETIAP exception** sebagai "sudah dipakai di
   transaksi". Error apa pun — DB terkunci, file rusak, bug baru — akan
   menyamar jadi pesan yang masuk akal dan tidak pernah terlihat. Ini kelas bug
   yang sama dengan `getOrElse` yang menelan `Left` di ADR-044, dan kedua
   kalinya ditemukan di repo ini: **jangan pernah menyimpulkan penyebab dari
   blok `catch` yang menangkap segalanya.** Kalau penyebabnya memang bisa
   dipastikan, pastikan dulu (di sini: cocokkan `FOREIGN KEY constraint
   failed`), sisanya diteruskan apa adanya.

Void sengaja tidak membebaskan produk: `voidTransaction` menandai
`status = 'voided'` dan baris `transaction_items`-nya tetap ada (soft delete,
ADR dan AGENTS.md §3), karena laporan lama membaca snapshot harga di baris itu.
Menghapus produknya akan mengosongkan FK yang masih dipakai laporan.

**Konsekuensi yang diterima.**

- **Produk yang pernah terjual menumpuk di daftar produk selamanya.** Pemilik
  hanya bisa menonaktifkannya — hilang dari kasir, tetap di daftar produk. Kalau
  itu jadi masalah nyata, yang dibutuhkan bukan hapus tapi fitur terpisah
  ("sembunyikan dari daftar produk"), dan itu keputusan baru: menghapus barisnya
  akan merusak laporan yang sudah ada.
- **Deteksi FK lewat pencocokan string** (`FOREIGN KEY constraint failed`),
  bukan kode error SQLite. Cukup karena satu-satunya FK yang masih menunjuk
  produk saat delete dijalankan adalah `transaction_items` — ledger stoknya
  dihapus di transaksi yang sama (`ProductDao.deleteProduct`). Kalau nanti ada
  tabel lain yang menunjuk `products`, pesannya akan salah dan **baris inilah
  yang harus dibaca lebih dulu**.
- **Satu query ekstra tiap hapus**: produknya diambil sebelum delete supaya
  pesan gagalnya bisa menyebut nama dan status aktifnya. Satu baris berindeks,
  dan hanya di jalur yang dipicu manusia.
- Jalur `rethrow` tidak punya tes: memaksa exception non-FK butuh fake DAO, dan
  satu-satunya yang akan diuji adalah bahwa pesannya tidak mengaku jadi masalah
  transaksi. Tiga tes yang ada mengunci aturan utamanya, termasuk bahwa void
  tidak membebaskan produk.

---

## ADR-046 — Lapisan token desain v2 diganti sekaligus, dan layar kamera dikecualikan

**Keputusan.** Langkah D1 `docs/implementasi_design.md`: `AppColor` turun dari
52 `static const` Material 3 ke **17 token semantik**, `AppSpacing` jadi
`s1/s2/s3/s4/s6` + `tapMin/tapPrimary/rowMin`, `AppRadius` jadi
`sm/md/lg/full`, `AppTextStyle` jadi 9 gaya. Semuanya dalam **satu commit**,
menyentuh 26 file. Empat aturan yang menyertainya:

1. **`fontFamily` dihapus, bukan diganti.** v1 menulis `'Inter'` padahal Inter
   tidak pernah didaftarkan di `pubspec.yaml`, jadi yang tampil di HP selama
   ini Roboto bawaan Android — dan desain v2 memilih Roboto secara sadar.
   Mengisinya lagi berarti menambah aset untuk hasil yang sama.
2. **`line` dan `lineStrong` adalah dua hal berbeda.** `line` hiasan (pemisah
   baris, tepi kartu); `lineStrong` satu-satunya garis yang menandai kontrol
   dan satu-satunya yang lolos 3:1 di atas `surface`. v1 hanya punya
   `outlineVariant` untuk keduanya, jadi pemisahan ini harus dijaga manual:
   batas chip filter, kotak ikon, dan titik PIN memakai `lineStrong`.
3. **Layar scanner sengaja tidak memakai token.** `barcode_scanner_screen.dart`
   menahan 16 hardcode `Colors.black*/white*` karena isinya gambar kamera,
   bukan permukaan aplikasi: scrim harus hitam transparan sungguhan dan garis
   bidik harus putih supaya terlihat di atas apa pun yang disorot. `ink` dan
   `surface` adalah warna kertas aplikasi dan akan membuat overlay lebih terang
   dari gambar di belakangnya. Design system v2 tidak mencakup overlay kamera.
   Alasannya ditulis sebagai komentar di `build` supaya tidak "dirapikan".
4. **Tidak ada tes untuk perubahan visual.** Tes yang mengunci nilai warna
   hanya menguji ulang isi file token: ia akan gagal setiap kali desain berubah
   dan tidak pernah menangkap bug. Gerbang D1 adalah `flutter analyze` + 173
   tes lama tetap hijau + verifikasi pemilik di HP.

**Alasan satu commit.** Menghapus satu token memaksa setiap pemanggilnya
berubah bersamaan, kalau tidak aplikasinya tidak kompilasi. Lapisan token
adalah satu-satunya bagian desain v2 yang **tidak bisa** dibuat bertahap;
sisanya (D2–D9) per layar.

**Temuan yang hanya muncul setelah token punya arti.** Pengingat backup dan
banner "perlu restok" keduanya merah, karena v1 memakai `errorContainer` untuk
keduanya. `tokens.json` v2 menulis eksplisit bahwa `warning` berarti *"Badge
Stok menipis, notice pengingat backup"* dan merah hanya untuk Void / Habis /
error. Pemetaan mekanis mewarisi arti yang salah; keduanya dipindah ke pasangan
kuning. **Pelajarannya untuk langkah berikutnya: rename token tidak pernah
murni mekanis** — pemetaan nama bisa benar sementara artinya salah, dan hanya
`tokens.json` yang bisa memutuskan.

**Konsekuensi yang diterima.**

- **Jarak menyusut di 10 tempat.** v2 tidak punya langkah 32px, jadi `xl` → 24.
- **Sudut membulat lebih besar**: `radius.sm` 4 → 8, `lg` 16 → 20. Ini bukan
  rename, nilainya memang berubah.
- **Bottom nav dan bottom sheet jadi putih**, bukan warna halaman seperti v1.
  `tokens.json` menyebut keduanya eksplisit di bawah `surface`; pemetaan
  mekanis menaruhnya di `bg` dan itu diperbaiki manual.
- **`ColorScheme` Material tetap diisi lengkap** walau v2 tidak punya
  `secondary`/`tertiary`: widget bawaan yang tidak kita beri style sendiri
  masih membacanya. Slot tanpa padanan diisi token yang paling tidak
  mengejutkan (`secondary` → `primary`, `tertiary` → `warning`), bukan warna
  baru. Jangan menambah warna di sana — tambah di `tokens.json` dulu.
- `dashboard_screen.dart`, `low_stock_screen.dart`, dan `pin_pad.dart` ikut
  ditokenisasi walau D2/D3 akan membongkar atau menghapusnya. Melewatkannya
  berarti aplikasinya tidak kompilasi hari itu.

Cross-link: ADR-043 (orientasi scanner) menyentuh file yang sama; aturan nomor
3 di atas menjelaskan kenapa file itu tidak ikut tokenisasi.

