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

---

## ADR-047 — Dasbor dibuang; Pengaturan turun dari tab jadi ikon gear

**Keputusan.** Desain v2 tidak punya Dasbor, dan ini bukan "belum digambar":
`lib/features/dashboard/` dihapus seluruhnya di D2, beserta rute `dashboard`.
Kasir jadi tab pertama dan layar pembuka. Tab keempat yang dulu Pengaturan
diisi Laporan; Pengaturan dibuka dari ikon gear di app bar Laporan.

**Alasan.** Dasbor adalah layar yang tidak dipakai saat bekerja: pemilik warung
membuka aplikasi untuk melayani pembeli, bukan untuk melihat angka. Menaruh
Kasir di balik satu ketukan tombol di Dasbor membuat pekerjaan yang dilakukan
ratusan kali sehari selalu satu langkah lebih jauh (PRD §1.5 menuntut
transaksi 3 item ≤ 30 detik). Pengaturan sebaliknya: dibuka beberapa kali
sebulan, jadi tidak layak memegang satu dari empat slot tab.

**Ke mana isi Dasbor pindah.**

| Bagian Dasbor | Rumah barunya |
|---|---|
| Omzet hari ini (`_RevenueCard`, `_StatsRow`) | Laporan, chip "Hari ini" — sudah ada di sana |
| Grafik 7 hari (`_RevenueChart`) | **dibuang**; v2 mengganti grafik dengan laba kotor (D8) |
| `BackupReminder` | Pengaturan, sebagai `Notice` (D8) |
| Tombol "Mulai transaksi" | **dibuang**; Kasir sudah jadi tab pertama |
| `_RestockList` (sudah di-comment) | **dihapus**; chip "Perlu restok" di Produk (D6) |

**Konsekuensi yang diterima.**

- **`SettingScreen` sekarang wajib punya app bar.** Sebagai tab ia tidak
  pernah butuh tombol kembali; sebagai layar yang di-*push*, tanpa app bar
  tidak ada jalan keluar. Jangan hapus app bar itu selama Pengaturan bukan tab.
- **Pengingat backup hilang dari mata pemilik sampai D8.** Yang tersisa badge
  "Perlu backup" di baris Backup di dalam Pengaturan — artinya pengingat itu
  hanya terlihat kalau pemilik sudah membuka Pengaturan, padahal gunanya justru
  mengingatkan orang yang tidak membukanya. Ini utang dengan batas waktu: D8.
- **`LowStockScreen` dihapus bersamaan**, jadi banner "N produk perlu restok"
  di layar Produk tidak bisa diketuk lagi sampai chip penggantinya lahir di D6.
  Bannernya dibiarkan tampil (informasinya masih benar), hanya `onTap`-nya
  dicabut — rute yang menuju layar yang sudah tidak ada akan melempar.
- `PageRoutes.mulaiTransaksi` berganti nama jadi `kasir`: rutenya berubah arti
  dari aksi ("mulai transaksi") jadi tempat (tab Kasir).

Cross-link: ADR-048 (umur `CartBloc`, konsekuensi langsung dari Kasir jadi
tab), ADR-012 (kenapa tidak ada tes widget untuk navigasinya).

---

## ADR-048 — `CartBloc` hidup di atas shell navigasi, bukan di dalam layar Kasir

**Keputusan.** `BlocProvider<CartBloc>` ada di `main.dart`, di atas
`MaterialApp.router`. `CashierScreen` **tidak** membuatnya.

**Alasan.** Selama Kasir masih rute penuh, keranjang lahir dan mati bersama
layarnya dan itu benar: keluar dari kasir memang berarti membatalkan
transaksi. Begitu Kasir jadi `StatefulShellBranch` (ADR-047), pindah ke tab
Produk bukan lagi "keluar dari kasir" — pemilik justru pindah ke sana untuk
mengecek stok atau menambah produk di tengah transaksi, lalu kembali. Kalau
blocnya tetap dibuat di dalam layar, `StatefulShellRoute` membangun ulang
branch-nya dan **keranjang yang sudah berisi 8 item hasil scan jadi kosong**,
tanpa pesan apa pun.

**Konsekuensi yang diterima.**

- **Keranjang seumur aplikasi.** Isinya baru hilang kalau dikosongkan,
  dibayar, atau aplikasinya ditutup. Itu memang yang diinginkan — tapi berarti
  keranjang yang ditinggalkan semalam masih ada besok pagi dengan harga yang
  mungkin sudah berubah. `priceAtSale` disnapshot saat bayar, bukan saat masuk
  keranjang, jadi angka yang tersimpan tetap harga saat transaksi.
- **Tombol back di tab Kasir menutup aplikasi**, karena tidak ada rute di
  bawahnya untuk di-pop. Konfirmasi "Tutup aplikasi? Keranjang yang belum
  dibayar akan hilang." tetap ada dan keluarnya lewat `SystemNavigator.pop()`.
  Jangan ganti dengan `Navigator.pop()`: di rute paling bawah itu tidak
  melakukan apa pun, jadi tombol Keluar akan terasa rusak.
- **Tidak ada tes otomatis yang menjaga ini.** `CartBloc` tidak punya konsep
  tab; yang menentukan keranjang bertahan adalah **posisi providernya di widget
  tree**, bukan isi blocnya, jadi tes bloc untuk ini hanya akan menguji ulang
  `flutter_bloc`. Penggantinya tiga komentar peringatan (`main.dart`,
  `injection_container.dart`, dartdoc `CashierScreen`) dan satu langkah uji
  manual: isi keranjang → pindah tab → kembali.
- Registrasinya di get_it tetap `registerFactory`, tapi dipanggil sekali saja
  dari `main.dart`. Komentar "tiap kunjungan ke kasir mulai dengan keranjang
  kosong" di `injection_container.dart` sudah **tidak benar** dan diperbarui.

Cross-link: ADR-047 (yang memicunya), ADR-051 (bug layout di layar yang sama).

---

## ADR-049 — PIN jadi bottom sheet; wadahnya berubah, aturannya tidak

**Keputusan.** `PinGate.require` membuka `PinVerifySheet` lewat
`showModalBottomSheet`, bukan `context.push` ke `PinVerifyScreen`. Rute
`verifikasi-pin` dan layarnya dihapus.

**Alasan.** Layar penuh membuang konteks: pemilik yang sedang mem-void
transaksi kehilangan tampilan transaksi itu persis saat ia harus memastikan
sedang mem-void yang benar. Sheet menyisakannya terlihat di belakang.

**Batas yang tidak boleh ikut berubah.** Sheet **hanya** mengganti wadah:

- Jeda bertingkat setelah salah berulang (5s → 30s → 5 menit) dan seluruh
  aturan `PinRepository` tetap apa adanya. Gerbangnya eksplisit: 9 tes
  `pin_repository_impl_test.dart` harus hijau **tanpa diubah**. Kalau suatu
  saat salah satunya perlu diubah demi wadah barunya, itu tanda wadahnya ikut
  mengubah aturan — hentikan, jangan sesuaikan tesnya.
- `PopScope(canPop: false)` selama status `loading`, supaya tombol kembali
  tidak membatalkan di tengah verifikasi: hitungan gagal sudah tercatat di
  titik itu, jadi membatalkannya diam-diam akan membuat jeda muncul tanpa
  sebab yang terlihat.
- Empat pemanggil (void, restore, ubah harga/modal, ganti PIN) tidak disentuh
  satu baris pun. Itu alasan `PinGate` dibuat sebagai pintu tunggal (ADR-028).

**Konsekuensi yang diterima.**

- Sheet bisa ditutup dengan menggeser ke bawah atau mengetuk latar — sama
  artinya dengan membatalkan (`false`), persis seperti tombol kembali di layar
  lama. Tidak ada aksi sensitif yang lolos karena ini: `require` hanya
  mengembalikan `true` kalau blocnya melaporkan sukses.
- Tes widget alur PIN sekarang masuk lewat `PinGate.require`, bukan dengan
  mendorong layar verifikasi langsung — kebetulan jadi lebih jujur: yang diuji
  jalur yang sungguhan dipakai, termasuk cabang "PIN belum dibuat".
- Penantian PBKDF2 di tes itu diganti dari satu `Future.delayed(3s)` tetap
  menjadi menunggu sampai UI-nya benar-benar berubah (maksimal 12 detik).
  Alasannya bukan selera: delay tetap itu **gagal sekali** saat suite penuh
  jalan paralel di mesin sibuk. Jangan kembalikan ke delay tetap; kalau butuh
  pola yang sama di tes lain, pakai `waitUntil` di file itu sebagai contoh.

Cross-link: ADR-028 (`PinGate` sebagai helper statis), ADR-012 (fake-async),
ADR-047 (D2 yang mendahuluinya).

---

## ADR-050 — Query terlaris kedua untuk kasir, dan apa yang mengisi "Sering dibeli"

**Keputusan.** `ProductDao.watchFrequentProducts()` ditambahkan **di samping**
`ReportDao.getBestSellers`, bukan menggantinya. Query baru mengelompokkan
`transaction_items.productId` lalu join ke `products` dan mengembalikan baris
produk utuh: 30 hari terakhir, hanya transaksi `completed`, hanya produk aktif
dan berstok, urut jumlah terjual, limit 5.

**Alasan.** `getBestSellers` mengelompokkan `transaction_items.productName` —
**snapshot nama**, tanpa id dan tanpa harga. Itu tepat untuk laporan (nama
historis harus ikut nama saat terjual, bukan nama produk sekarang), tapi
hasilnya tidak bisa dimasukkan ke keranjang: `CartItem` butuh `ProductEntity`
utuh. Memaksa yang lama dipakai berarti mencari produk berdasarkan nama, dan
nama bukan kunci — produk yang sudah di-rename atau dihapus akan cocok ke
produk yang salah atau tidak cocok sama sama sekali.

Jadi dua query ini memang menjawab dua pertanyaan berbeda: "apa yang terjual"
(sejarah, nama snapshot) dan "apa yang bisa saya jual sekarang" (produk hidup).
Jangan digabung.

**Yang disaring di SQL, dan kenapa.** Produk nonaktif dan stok habis tidak
muncul karena tidak bisa masuk keranjang — kalau disaring di UI, `limit 5`
sudah terpakai oleh baris yang kemudian dibuang, dan daftarnya bisa tampil
berisi dua produk padahal ada lima yang layak. Transaksi `voided` tidak
dihitung: void berarti penjualan itu dianggap tidak pernah terjadi.

**Isi daftarnya saat belum ada riwayat.** Toko baru tidak punya penjualan, jadi
query ini mengembalikan kosong. Kalau dibiarkan, kasir tidak punya apa pun
untuk diketuk sampai transaksi pertama selesai — padahal transaksi pertama itu
yang sedang coba dilakukan. Jadi ada fallback: judulnya berganti jadi "Produk
siap jual" dan isinya produk aktif berstok dari `ProductBloc`, tanpa query
tambahan.

**Chip kategori di Kasir mengganti daftarnya** (keputusan pemilik 2026-11-10;
mockup tidak menjelaskan chip itu memfilter apa). "Semua" + kotak cari kosong
→ terlaris 30 hari. Pilih kategori atau ketik di kotak cari → daftar berganti
jadi produk kategori itu / hasil cari, difilter dari state `ProductBloc` tanpa
query baru. Chip hanya muncul untuk kategori yang punya produk **siap jual**:
aturan yang sama dengan layar Produk (ADR-038), bedanya di sini stok ikut
dihitung karena yang habis tidak bisa dijual.

**Konsekuensi yang diterima.**

- `since` dihitung sekali saat stream dibuat (`initState`), jadi aplikasi yang
  dibiarkan terbuka berhari-hari memakai jendela 30 hari yang ikut menua.
  Ditandai `shortcut:` di DAO. Naikkan ke tanggal SQL kalau jadi masalah nyata.
- `ProductDao` sekarang ikut membaca `TransactionItems` dan `Transactions`.
  Itu melebar dari "DAO satu tabel", tapi query ini **harus** join, dan
  rumahnya di DAO produk karena yang dikembalikan baris produk.
- Kalau nanti biayanya terasa tidak sepadan, pilihan "daftar produk aktif
  biasa" tinggal menghapus satu `StreamBuilder` — tapi itu keputusan pemilik,
  bukan keputusan saat menulis kode.

Cross-link: ADR-032 (agregat laporan dihitung di memori), ADR-038 (chip
kategori hanya untuk kategori berisi).

---

## ADR-051 — `Column` di dalam `bottomNavigationBar` wajib `mainAxisSize.min`

**Keputusan.** Setiap `Column` yang jadi isi `Scaffold.bottomNavigationBar`
harus `mainAxisSize: MainAxisSize.min`, atau tingginya dibatasi `SizedBox`.
Berlaku untuk PayBar Kasir, batang "Selesaikan transaksi", dan batang tombol
di layar Struk.

**Bug yang melahirkannya** (ditemukan pemilik saat verifikasi D2–D5): begitu
satu produk masuk keranjang, **keranjang dan daftar produk hilang sama sekali**
dan tombol Bayar mengambang di tengah layar.

**Penyebabnya.** `Scaffold` melayout `bottomNavigationBar` dengan batas
**longgar setinggi layar penuh**, bukan setinggi isinya. `Column` default
`mainAxisSize.max`, jadi ia mengambil seluruh 844 px yang ditawarkan. PayBar
jadi setinggi layar, `body` Scaffold kebagian **0 px**, dan `ListView` yang
tingginya nol **tidak membangun satu pun anaknya** — itu sebabnya dua bagian
hilang bersamaan padahal keduanya ada di tree. Gejalanya menyesatkan: yang
terlihat "memenuhi layar" bukan yang rusak, tapi batang di bawahnya.

**Pelajarannya, dan ini yang penting untuk D6–D9.** Batas longgar bukan batas
ketat: `maxHeight` yang besar tetap "boleh dipakai seluruhnya", dan setiap
widget yang rakus (`Column` max, `Expanded`, `Spacer`) akan memakainya. Setiap
batang bawah yang ditambahkan nanti harus dibaca dengan asumsi itu.

**Batas ADR-012 yang jadi jelas.** Kelas bug ini **bisa** dijaga
`testWidgets`, karena yang diuji **geometri, bukan data**: tidak ada stream
Drift yang perlu maju. `test/features/transaction/cashier_layout_test.dart`
memalsukan semua repository dengan stream kosong (`Fake` + `Stream.value`),
dan hanya satu `WatchFrequentProducts` didaftarkan ke get_it — tanpa
`initDependencies`, jadi tanpa DB, tanpa timer, tanpa isolate. Tesnya
dibuktikan dua arah: merah sebelum perbaikan (`Found 0 widgets with text
"Keranjang · 1 produk"`), hijau sesudah.

Jadi aturan ADR-012 dipertajam, bukan dibatalkan: yang tidak bisa diuji
`testWidgets` adalah alur yang **menunggu data dari Drift**. Layout, validator,
dan teks tetap bisa — dan untuk layar yang punya batang bawah, memang harus.

**Konsekuensi yang diterima.** Perbaikan ini juga dipasang di batang bawah
layar Struk walau pemilik belum pernah melihat layar itu rusak: bentuknya
identik, jadi menunggu bug yang sama muncul lagi hanya membuang satu putaran
verifikasi.

Cross-link: ADR-012 (batas tes widget, dipertajam di sini), ADR-048 (layar yang
sama), ADR-013 (bug yang lolos karena layarnya tidak punya tes).

---

## ADR-052 — Chip "Perlu restok" memakai query lama, dan isinya beda dari `isLowStock`

**Keputusan.** Chip `Perlu restok · N` di layar Produk disaring dengan
`ProductState.lowStockProducts` — hasil `watchLowStockProducts()` yang sudah
ada sejak awal — bukan dengan getter `ProductEntity.isLowStock`, dan bukan
dengan query baru.

**Kenapa bukan query baru.** Daftarnya sudah di state: `LowStockScreen` dulu
memakainya, dan ketika layar itu dihapus di D2 querynya tetap berlangganan
untuk banner. Chip ini hanya mengganti cara menampilkannya.

**Yang harus tidak diubah karena terlihat seperti kesalahan.** Dua definisi
"stok menipis" di aplikasi ini **sengaja berbeda**:

| Sumber | Aturan | Stok 0 |
|---|---|---|
| `ProductDao.watchLowStockProducts` | `stock <= lowStockThreshold` | **ikut** |
| `ProductEntity.isLowStock` | `stock > 0 && stock <= threshold` | tidak |

Chip memakai yang pertama: produk habis adalah yang **paling** perlu restok,
jadi mengeluarkannya dari daftar restok akan menyembunyikan justru yang
mendesak. Badge di baris memakai yang kedua, karena badge `Habis` merah sudah
mengambil kasus stok 0 dan dua badge di satu baris tidak berguna.

Konsekuensinya angka N di chip **lebih besar** dari jumlah badge `Sisa N` yang
terlihat, sebanyak produk yang habis. Itu benar, bukan selisih yang perlu
"diperbaiki" dengan menyeragamkan kedua definisi. `visibleProducts` menerima
daftar low-stock sebagai parameter justru supaya aturan ini tidak bisa
diam-diam dihitung ulang di presentation, dan tesnya mengunci bahwa produk
stok 0 ikut muncul.

**Badge "Stok aman" dibuang.** Dulu setiap produk dapat badge, termasuk hijau
"Stok aman". Di daftar 86 produk hasilnya 86 badge hijau yang menenggelamkan
4 yang benar-benar butuh tindakan. Sekarang hanya keadaan yang perlu
tindakan yang diberi badge: `Nonaktif`, `Habis`, `Sisa N`.

Cross-link: ADR-038 (kategori kosong tidak jadi chip, aturan yang sama dipakai
chip kategori di sini), ADR-047 (`LowStockScreen` dihapus, chip ini
penggantinya), ADR-012 (`visibleProducts` dipisah jadi fungsi murni supaya
bisa diuji `test()`).

---

## ADR-053 — Aksi baris produk pindah ke satu sheet, bukan ikon di baris

**Keputusan.** Mengetuk baris produk membuka `ProductActionSheet` berisi empat
pilihan: Ubah produk, Restok, Koreksi stok, Hapus. Ikon pensil dan menu tiga
titik di baris dihapus.

**Kenapa.** Baris produk di mockup v2 adalah satu tombol tanpa ikon, dan di
390 px baris yang memuat avatar, nama, kategori, stok, badge, harga, **plus**
dua sasaran ketuk 48 px tidak punya ruang tanpa memotong nama produk. Pemilik
memilih opsi ini dari tiga yang ditawarkan; dua lainnya (geser baris dengan
`flutter_slidable`, dan mempertahankan ikon) ditolak karena yang pertama
menambah paket untuk aksi yang tidak punya petunjuk di layar, dan yang kedua
tidak pernah bisa sama dengan mockup.

**Keuntungan yang tidak direncanakan tapi nyata.** "Hapus" tidak lagi bisa
tersenggol: dulu ia satu ketukan di dalam menu yang dibuka ikon kecil di
sebelah ikon Ubah, sekarang ia selalu butuh satu ketukan niat di sheet yang
menyebut nama produknya. Produk yang pernah terjual tetap tidak bisa dihapus
(ADR-045), tapi yang belum pernah terjual **bisa**, dan itu kerugian data yang
tidak bisa dibatalkan.

**Sheet-nya hanya memilih, tidak mengerjakan.** `ProductActionSheet.show`
mengembalikan `ProductAction?` dan pemanggil yang menjalankan aksinya. Itu
bukan selera: Restok dan Koreksi membuka `StockSheet`, dan membuka sheet dari
dalam sheet yang belum tertutup meninggalkan sheet pertama menggantung di
bawah yang kedua. Jangan dipindah ke dalam sheet ini.

Cross-link: ADR-045 (produk yang pernah terjual tidak boleh dihapus),
ADR-011 (perubahan stok wajib lewat Restok/Koreksi supaya ledger tidak bolong —
sebabnya kedua aksi itu harus tetap ada di sini).

---

## ADR-054 — Void jadi satu sheet: dampak, alasan, dan PIN dalam satu tampilan

**Keputusan.** Void transaksi sekarang **satu** `VoidSheet`: ringkasan dampak,
chip alasan, PIN pad, tombol "Void transaksi". Alur dua langkah (sheet PIN
dulu, lalu `AlertDialog` alasan) dihapus beserta `_VoidReasonDialog`.

**Kenapa.** Di alur lama pemilik memasukkan PIN **sebelum** tahu alasan apa
yang akan dicatat dan berapa stok yang akan kembali — menyetujui gerbang untuk
sesuatu yang baru dijelaskan di layar berikutnya. Void mengubah stok dan uang,
dan di sinilah PIN betul-betul menjaga sesuatu, jadi yang dijaga harus terbaca
saat gerbangnya dilewati.

**PIN sengaja tidak auto-submit di sheet ini.** `PinVerifySheet` mengirim PIN
begitu angka ke-6 ditekan; di sini tidak. Tombol "Void transaksi" yang memicu,
karena:

1. alasan wajib terisi dan auto-submit membuat PIN bisa benar sementara alasan
   masih kosong, dan
2. pemilik harus tetap bisa batal **setelah** mengetik PIN — di alur lama,
   angka ke-6 langsung melewati gerbang.

Tombolnya mati sampai alasan terisi **dan** enam angka lengkap.

**Yang tidak berubah, dan harus tetap begitu.** `PinBloc`/`PinRepository` tidak
disentuh: jeda bertingkat, hitungan gagal, dan hash di secure storage tetap
sama, buktinya 9 tes `pin_repository_impl_test` hijau tanpa diubah. Sheet ini
mem-`pop` **alasannya**, bukan mem-void sendiri; `voidTransaction` tetap
dipanggil `TransactionDetailScreen`, jadi validasi repository (alasan kosong
ditolak, transaksi yang sudah void ditolak) tetap jaring terakhir dan tes void
di repository tetap hijau tanpa diubah.

**`PinGate.hasPinOrWarn` dibuka.** Sheet ini memasang keypad-nya sendiri
sehingga tidak lewat `PinGate.require`, tapi pemeriksaan "PIN belum pernah
dibuat" tidak boleh disalin: kalau gerbangnya nanti berubah, salinan itu yang
akan ketinggalan. `require` sekarang memanggil helper yang sama.

**Chip alasan menggantikan ketik bebas, tapi tidak menghapusnya.** `Lainnya`
tetap membuka kolom teks: `voidReason` wajib terisi dan alasan di luar tiga
pilihan itu harus tetap bisa dicatat.

Cross-link: ADR-049 (PIN jadi sheet; sheet ini pengecualian yang memasang
keypad sendiri), ADR-028 (empat pemanggil `PinGate` tidak berubah), ADR-051
(tombol di sheet ini dipatok `SizedBox`, bukan dibiarkan `Column` mengambil
ruang).

---

## ADR-055 — `pop()` dari dalam listener barcode wajib menutup celah `await` lebih dulu

**Keputusan.** Mode `BarcodeScannerScreen(returnsCode: true)` men-set
`_isBusy = true` **sebelum** `await` apa pun, bukan sesudah.

**Bug yang melahirkannya** (ditemukan pemilik saat verifikasi D6, hanya untuk
produk yang **sudah terdaftar**):

```
Exception caught by widgets library
'package:flutter/src/widgets/navigator.dart': Failed assertion:
line 4128 pos 12: '!_debugLocked': is not true.
```

**Penyebabnya.** `!_debugLocked` berarti `Navigator.pop()` dipanggil sementara
`pop()` lain masih mengubah widget tree. Urutannya: barcode terbaca →
`await HapticFeedback.mediumImpact()` → **deteksi kedua masuk di celah await
itu** → lolos semua penjaga → `pop()` kedua jatuh di tengah `pop()` pertama.

**Kenapa hanya produk terdaftar.** Bukan karena lookup produknya — di mode ini
tidak ada lookup sama sekali. Produk terdaftar punya barcode **cetak asli**
yang dikenali kamera berkali-kali per detik; kode uji yang belum terdaftar
biasanya terbaca sekali, jadi celahnya tidak pernah terisi. Gejala yang
seolah-olah berkaitan dengan status pendaftaran sebenarnya berkaitan dengan
**laju deteksi**.

**Kenapa jalur keranjang tidak pernah kena.** Penjaganya sudah ada sejak awal:
`_onDetect` dibuka `if (_isBusy) return;`, dan jalur keranjang men-set
`_isBusy = true` sebelum `await` lookup database. Early-return mode
`returnsCode` ditulis **di atas** blok `setState` itu, jadi satu-satunya
mekanisme yang membuat `pop` di file ini aman justru terlewat. Perbaikannya
memakai penjaga yang sama, bukan mekanisme baru.

**Aturan umumnya, untuk setiap `pop` berikutnya di layar ini.** Antara deteksi
dan `pop` tidak boleh ada `await` yang belum dilindungi `_isBusy` — termasuk
`await` yang kelihatan tidak berbahaya seperti haptic.

**Tidak bisa dijaga tes otomatis, dan jangan dipaksakan.** `_onDetect` hidup di
dalam `State` yang membuat `MobileScannerController`, dan controller itu butuh
platform channel kamera yang tidak ada di `flutter test`
(`MissingPluginException`); memalsukannya berarti memalsukan plugin di kode
produksi, yang dilarang ADR-012. Tes yang mem-pop dua kali lewat `Navigator`
biasa hanya menguji ulang Flutter, bukan kode ini. Penggantinya pemeriksaan
manual yang spesifik: tahan barcode terdaftar 2–3 detik di depan kamera dari
**Produk → scan**, ulangi 3–4 kali — menahannyalah yang memicu deteksi
berturut, dan sekali lolos belum berarti sembuh.

Cross-link: ADR-012 (batas tes widget; ini kasus yang benar-benar di luar
jangkauannya, berbeda dari ADR-051 yang justru bisa diuji), ADR-043 (layar
scanner yang sama), ADR-025 (aturan operasional yang harus ikut ditulis di
`AGENTS.md`, bukan hanya di ADR).

---

## ADR-056 — Preset laporan terpanjang adalah bulan **kalender**, bukan 30 hari bergulir

**Keputusan.** Chip ketiga di Laporan berbunyi "Bulan ini" dan rentangnya
tanggal 1 bulan berjalan sampai akhir hari ini. Preset "30 hari" yang ada sejak
langkah 12 dihapus, bukan ditambahi.

**Kenapa, dan kenapa ini pertanyaan untuk pemilik.** Mockup v2 menulis
"30 hari" sementara `docs/implementasi_design.md` tidak menyebut keduanya, jadi
kode lama dan gambar baru saling bertentangan tanpa satu pun yang berwenang.
Pemilik memilih bulan kalender: angka yang dipakainya adalah setoran bulanan,
dan "30 hari terakhir" pada tanggal 5 menjawab pertanyaan yang tidak pernah
ditanyakan — ia mencampur dua bulan.

**Konsekuensi yang diterima.** Tanggal 1, "Bulan ini" hanya memuat satu hari
dan grafiknya satu titik. Itu benar, bukan bug: bulan itu memang baru satu
hari. Dan panjang periode sekarang berubah-ubah 28–31 hari, jadi
`ReportPeriod.days` yang tetap **dihapus**; penghitung hari diturunkan dari
rentangnya (`_daily` menerima `start` dan `end`, bukan jumlah hari). Satu
konstanta yang tidak bisa lagi benar lebih berbahaya daripada tidak ada
konstanta.

**Batas hari kalender tetap sama seperti sebelumnya.** `end` = awal hari esok
minus satu mikrodetik, dan perulangan harinya memakai `DateTime(y, m, d + i)`,
bukan `add(Duration(days: i))`, supaya pergantian DST tidak menggeser ember
harian. Aturan yang sama dipakai `historyRange` di Riwayat.

Cross-link: ADR-032 (agregasi laporan masih di memori; preset terpanjang
sekarang sebulan, bukan 30 hari), ADR-047 (Dasbor dibuang, jadi Laporan satu-
satunya tempat angka periode).

---

## ADR-057 — Laba kotor: angkanya dihilangkan dari widget tree sampai PIN benar

**Keputusan.** Nilai laba kotor di Laporan ditampilkan `••••••` + ikon kunci.
Setelah `PinGate.require` sukses, baru `formatRupiah(report.grossProfit)` yang
dirender. Sebelum itu angkanya **tidak pernah masuk widget tree**.

**Kenapa dipilih pemilik, dari tiga pilihan.** Rencana sengaja menyisakan
pertanyaan ini. Pilihan "biarkan terbuka" ditolak pemilik; pilihan "tutup
dengan blur/opacity" ditolak di sini karena menyembunyikan dengan `Opacity`
atau warna transparan hanya menipu mata: angkanya tetap ada di tree, terbaca
oleh screen reader, dan ikut tertangkap screenshot tool atau dump widget.
Ambang yang dipakai: **tidak ada di tree** = benar-benar tidak ada.

**Kapan terkunci lagi.** Dua pemicu, keduanya disengaja:

1. ganti chip periode — angka periode baru belum pernah dibuka;
2. `didChangeAppLifecycleState != resumed` — HP dikunci atau aplikasi
   ditinggalkan.

**Yang tidak dibangun, dan konsekuensinya.** Tidak ada timeout. Selama layarnya
tetap terbuka dan aplikasi tetap di depan, angkanya terlihat sampai pemilik
pindah periode. Kalau HP berpindah tangan dalam keadaan itu, angkanya terbaca.
Diterima: ini satu HP satu pemilik (PRD §1.6), dan timeout yang mengunci
sendiri saat pemilik sedang membaca lebih mengganggu daripada melindungi.

**`PinGate` dibuka ke pemakai kelima tanpa diubah.** Jalurnya sama dengan void,
restore, dan ubah harga/modal — tidak ada mekanisme PIN baru, tidak ada
`PinBloc` kedua. Yang bertambah hanya satu `reason` baru.

**Dijaga tes, dan ini bagian yang mudah rusak tanpa sadar.**
`test/features/report/report_profit_lock_test.dart` memastikan `Rp 312.000`
`findsNothing` sementara omzet dan jumlah transaksi `findsOneWidget`. Siapa pun
yang nanti mengganti cara menyembunyikannya dengan trik visual akan
menjatuhkan tes itu — itu memang tujuannya. Yang **tidak** diuji: jalur PIN
benar, karena `PinGate` memanggil `sl<PinRepository>()` yang tidak dipalsukan
di tes itu.

Cross-link: ADR-028 (empat pemanggil `PinGate` sebelumnya), ADR-049 (PIN jadi
sheet), ADR-054 (pengecualian: void memasang keypad sendiri), ADR-012 (batas
tes widget — geometri dan visibilitas bisa diuji, DB tidak).

---

## ADR-058 — `CrossAxisAlignment.stretch` di dalam area yang bisa di-scroll wajib dibungkus `IntrinsicHeight`

**Keputusan.** Dua kartu angka berdampingan di Laporan dibungkus
`IntrinsicHeight`, bukan dibiarkan `Row(crossAxisAlignment: stretch)` saja.

**Bug yang melahirkannya.** Versi pertama D8 crash begitu Laporan dibuka:

```
BoxConstraints forces an infinite height.
The offending constraints were:
  BoxConstraints(0.0<=w<=Infinity, h=Infinity)
```

**Penyebabnya.** `stretch` meminta anak setinggi batas atas tinggi `Row`.
Di dalam `ListView` batas itu tak terbatas, jadi anaknya diminta setinggi
infinity. `IntrinsicHeight` yang mengukur anak tertinggi lebih dulu dan
memberi `Row` tinggi nyata.

**Kenapa bukan dengan membuang `stretch`.** Keduanya memang harus sama tinggi:
ikon kunci 16 px di kartu laba membuat sisi itu beberapa piksel lebih tinggi
dari kartu Transaksi, dan dua kartu berdampingan yang beda tinggi beberapa
piksel terlihat seperti salah render. `IntrinsicHeight` satu baris; mematok
tinggi dengan angka tetap akan patah begitu ukuran font sistem dinaikkan.

**Yang menarik: ini ditemukan suite, bukan HP.** Tes widget yang ditulis untuk
alasan lain (kunci laba, ADR-057) yang menjatuhkannya. Pasangan ADR ini yang
menandai batas tes widget di proyek ini dengan tepat: **geometri bisa diuji**
(ADR-058 dan ADR-051 sama-sama soal constraint), **kamera tidak** (ADR-055).
Jangan pakai ADR-055 sebagai alasan melewatkan tes layout.

**Aturan umumnya,** ikut ditulis di `AGENTS.md` §3 karena harus dipatuhi saat
menulis kode: `stretch` hanya aman kalau tinggi induknya sudah pasti. Di dalam
`ListView`, `Column` yang bisa di-scroll, atau `SingleChildScrollView`,
bungkus `IntrinsicHeight` atau patok `SizedBox`.

Cross-link: ADR-051 (keluarga bug yang sama dari sisi lain: slot dengan
constraint longgar di `bottomNavigationBar`), ADR-012, ADR-057 (tes yang
menemukannya).

---

## ADR-059 — `styleFrom(...).copyWith(backgroundColor:)` wajib menangani `WidgetState.disabled`

**Keputusan.** Cabang `disabled → AppColor.surfaceMuted` di
`elevatedButtonTheme` bukan hiasan; tanpa itu tema ini salah.

**Kenapa.** `ElevatedButton.styleFrom` mengisi warna disabled sendiri, tapi
`copyWith(backgroundColor: ...)` menggantinya untuk **semua** `WidgetState`
sekaligus — termasuk disabled. Jadi menambahkan warna tekan (`primaryPressed`,
D9) ikut menghidupkan kembali tampilan tombol yang sedang mati: "Menyimpan..."
saat form sedang menyimpan dan "Bayar" saat uang belum cukup akan tampak bisa
ditekan padahal `onPressed` null. Pemilik akan menekannya berulang dan menyimpulkan
aplikasinya menggantung.

**Konsekuensi.** Setiap penambahan state ke `backgroundColor` tombol di tema
ini harus menyebut `disabled` secara eksplisit, karena `resolveWith` tidak
mewarisi apa pun dari `styleFrom`. Aturan ini ikut ditulis di `AGENTS.md` §3.

**Ditemukan saat memperbaiki kesalahan lain** (splice tema D9 meninggalkan koma
nyasar), bukan oleh tes: warna tombol mati tidak dijaga tes mana pun, dan
menulisnya berarti menguji ulang Material. Penggantinya aturan di atas.

Cross-link: ADR-046 (lapisan token v2; `primaryPressed` lahir di sana tanpa
pemakai sampai D9).
