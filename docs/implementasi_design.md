# Rencana Implementasi Desain v2 — Henshin POS

Rencana bertahap penerapan `design/design_v2/` ke kode. Disusun 2026-11-09 atas
permintaan pemilik. Pelengkap `docs/implementasi.md` (langkah 1–15, **sudah
selesai semua**), bukan penggantinya — penomorannya dipisah **D1–D9** supaya
tidak pernah tertukar dengan "langkah" rencana lama.

**Status:** D1 selesai & diverifikasi 2026-11-09. D2–D5 selesai &
diverifikasi 2026-11-10 (ADR-047 s/d ADR-051). **D6–D7 selesai &
diverifikasi 2026-11-12** (ADR-052 s/d ADR-055). Berikutnya D8.

**Sumber kebenaran desain**, berurutan:

1. `design/design_v2/henshin-design-system-v2/tokens.json` — angka token.
2. `.../README.md` — prinsip, tabel pemetaan v1 → v2, daftar ikon, copy.
3. `design/design_v2/<Layar>-html/*.dc.html` — susunan tiap layar. Nilai
   desainnya ada di atribut `style="…"`; README tiap folder menegaskan ini
   **referensi, bukan kode produksi**.

Aturan kerja tetap `AGENTS.md` §5: satu langkah per waktu, tidak mulai langkah
berikutnya tanpa persetujuan pemilik, dan tiap langkah yang diverifikasi
ditutup dengan tiga artefak (pesan commit, `docs/progress.md`, ADR).

---

## Keputusan pemilik yang sudah final

Tiga dari tiket `.scratch/desain-v2/issues/01-terapkan-desain-v2.md`
(dijawab 2026-11-09):

1. **Dasbor benar-benar dibuang.** Bukan belum digambar — memang tidak ada
   lagi. Kasir jadi tab pertama dan layar pembuka.
2. **Langkah 14–15 sudah selesai**, jadi tabrakan urutan yang dicatat tiket
   sudah tidak ada: Restore dan Void sudah berwujud sebelum desain diterapkan.
3. **Bertahap**, dengan rancangan tertulis lebih dulu — dokumen ini.

Empat lagi muncul saat membaca mockup, karena mockup memuat hal yang **belum
ada di aplikasi**. Dijawab pemilik 2026-11-09:

4. **"Sering dibeli" di Kasir diisi produk terlaris 30 hari.** Bukan daftar
   semua produk. Konsekuensinya ada di D4 — ini satu-satunya keputusan desain
   yang menyentuh lapisan data.
5. **Baris "Isi: 86 produk · 1.912 transaksi" di Pengaturan dibuang.** Tidak
   ada query hitung baru.
6. **App bar Riwayat dikosongkan.** Ikon "Cari transaksi" di mockup tidak
   dibangun (pencarian transaksi fitur baru, tidak ada di PRD), dan ikon ekspor
   mati yang ada sekarang dihapus — menutup satu baris utang teknis.
7. **`LowStockScreen` dihapus**, diganti chip "Perlu restok · N" di layar
   Produk. Ringkasan di Laporan menautkan ke chip itu.

---

## Prinsip pengerjaan

**Komponen dibangun saat dipakai, bukan di muka.** Design system v2 punya 14
komponen, tapi membangun 14 widget sebelum ada layar yang memakainya berarti
menulis kode yang belum punya pemanggil. Aturannya: tulis inline di layar
pertama yang membutuhkannya, **angkat jadi widget bersama begitu layar kedua
membutuhkannya**. Yang sudah pasti dipakai ≥2 layar sejak awal — `Badge`,
`Chip`, `ProductRow`, `Field` — boleh langsung diangkat di langkah tempat
pemakai keduanya muncul, bukan sebelumnya.

**Di mana widget bersama tinggal.** `lib/core/widgets/`. Folder baru, sejajar
`core/theme`. Alasannya komponen ini milik design system, bukan milik satu
fitur, dan `AGENTS.md` §2 melarang fitur mengimpor `presentation/` fitur lain.
Ini penambahan struktur folder — dicatat di ADR langkah D3.

**Tes.** Aturan `AGENTS.md` §3 tetap berlaku dan sudah terbukti dua kali:
`testWidgets` berjalan fake-async sehingga stream Drift tidak maju (ADR-012,
dibuktikan ulang saat kategori produk). Jadi:

- Logika yang bisa dipisah jadi fungsi murni **dipisah dan diuji** `test()`.
- Tes widget hanya untuk yang murni UI: widget muncul, teks benar, validator
  menyala.
- Perubahan visual murni (warna, jarak, radius) **tidak diuji otomatis** —
  `flutter analyze` + verifikasi pemilik di HP adalah gerbangnya. Jangan
  menulis tes yang mengunci nilai warna: itu menguji ulang isi file token.

**Gerbang tiap langkah:** `flutter analyze` bersih + suite penuh hijau
(sekarang 173) + pemilik melihat layarnya di HP.

---

## Pemetaan token (dipakai di D1, jangan ditebak ulang)

### Warna — 36 token v1 terpakai → 17 token v2

| v1 | pemakaian | v2 |
|---|---|---|
| `onSurface` | 54 | `ink` |
| `outline` | 25 | `inkMuted` kalau teks/ikon; `lineStrong` kalau batas kontrol |
| `error` | 21 | `danger` |
| `surface` | 18 | `bg` |
| `onSurfaceVariant` | 14 | `inkMuted` |
| `onPrimary` | 13 | `onPrimary` |
| `outlineVariant` | 12 | `line` |
| `surfaceContainerLowest` | 10 | `surface` |
| `background` | 9 | `bg` |
| `onErrorContainer` | 8 | `danger` |
| `primary` | 7 | `primary` |
| `errorContainer` | 6 | `dangerSoft` |
| `surfaceContainerLow` | 5 | `surfaceMuted` |
| `primaryContainer` | 5 | `primary` |
| `divider` | 5 | `line` |
| `secondaryContainer` | 3 | `primarySoft` |
| `tertiary`, `tertiaryContainer` | 3 | `warning` |
| `tertiaryFixed`, `warningColor` | 3 | `warningSoft` |
| `onSecondaryContainer` | 2 | `primary` (teks di atas `primarySoft`) |
| `onPrimaryContainer`, `onError`, `onTertiary`, `onTertiaryContainer`, `onSecondary` | 7 | `onPrimary` |
| `onTertiaryFixed` | 1 | `warning` |
| `inverseSurface` | 2 | `ink` |
| `inverseOnSurface` | 2 | `surface` |
| `secondary` | 1 | `inkMuted` |
| `primaryFixed`, `primaryFixedDim`, `secondaryFixed` | 3 | `primarySoft` |
| `inputBackground` | 1 | `surfaceMuted` |
| `discountBadge` | 1 | **dihapus** — diskon di luar scope (PRD §1.4) |

`outline` adalah satu-satunya yang **tidak bisa diganti dengan sed**: 25
pemakaian harus dibaca satu per satu, karena v2 sengaja memisahkan garis
dekoratif (`line`) dari garis yang menandai kontrol (`lineStrong`, 3:1).

### Jarak

| v1 | nilai | v2 | nilai |
|---|---|---|---|
| `xs` | 4 | `s1` | 4 |
| `sm` | 8 | `s2` | 8 |
| — | — | **`s3`** | **12 (baru)** |
| `md` | 16 | `s4` | 16 |
| `lg` | 24 | `s6` | 24 |
| `xl` | 32 | `s6` | **24 — mengecil, 10 tempat** |
| `xxl` 40, `xxxl` 48 | | `s6` / `tapMin` | per pemakaian |
| `touchTargetMin` | 48 | `tapMin` | 48 |
| — | — | **`tapPrimary`** | **56 (baru)** |
| — | — | **`rowMin`** | **64 (baru)** |
| `unit`, `gutter`, `containerPadding` | | **dihapus** | tidak dipakai di `lib/` |

### Radius

| v1 | nilai | v2 | nilai |
|---|---|---|---|
| `sm` | 4 | `sm` | **8 — berubah** |
| `_default` | 8 | `sm` | 8 |
| `md` | 12 | `md` | 12 |
| `lg` | 16 | `lg` | **20 — berubah** |
| `xl` | 24 | `lg` | 20 |
| `full` | 9999 | `full` | 999 |

Konstanta `*All` (`mdAll`, `lgAll`, …) **tetap ada** — Flutter butuh
`BorderRadius`, bukan `double`, di hampir semua tempat; yang berkurang
jumlahnya, bukan bentuknya.

### Teks — 7 gaya v1 → 9 gaya v2

| v1 | pemakaian | v2 |
|---|---|---|
| `displayPrice` 48px | 1 | `amount` 36px |
| `headlineLg` 32px | 9 | `title` 22px |
| `headlineMd` 24px | 7 | `title` 22px atau `heading` 17px, per pemakaian |
| `bodyLg` 18px | 4 | `heading` 17px atau `body` 16px, per pemakaian |
| `bodyMd` 16px | 35 | `body` |
| `labelSm` 13px | 27 | `label` 14px; `caption` 12px **hanya** untuk badge dan label tab |
| — | — | **`stat`** 22px, **`bodyStrong`** 16px/600, **`receipt`** mono 13px (baru) |

**Font.** `AppTextStyle` v1 menulis `fontFamily: 'Inter'` padahal Inter tidak
pernah didaftarkan di `pubspec.yaml`, jadi yang tampil selama ini Roboto. v2
memilih Roboto secara sadar → `fontFamily` dihapus, bukan diganti. Nol aset
baru.

**Angka uang** dapat `fontFeatures: [FontFeature.tabularFigures()]` di
`amount`, `stat`, dan `bodyStrong`, supaya digit tidak bergeser saat angka
berubah.

---

## Langkah

Urutan ini bukan selera: D1 menyentuh semua file sekaligus sehingga harus
lebih dulu; D2 memindahkan rumah beberapa layar sehingga harus sebelum
layar-layar itu dirapikan; D3 mengubah alur PIN yang dipakai empat pemanggil.
Sisanya per layar dan boleh ditukar urutannya.

---

### D1 — Lapisan token

**Tujuan.** `AppColor` 52 → 17 token, `AppSpacing` → `s1/s2/s3/s4/s6` +
`tapMin/tapPrimary/rowMin`, `AppRadius` → `sm/md/lg/full`, `AppTextStyle` →
9 gaya v2 tanpa `fontFamily`. Semua pemanggil ikut diperbarui, plus 24
hardcode `Colors.*` di `lib/features/`.

**Tidak bisa dibuat bertahap.** Menghapus satu token berarti setiap
pemanggilnya harus ikut berubah di commit yang sama, kalau tidak aplikasinya
tidak kompilasi. Inilah satu-satunya langkah besar di rencana ini.

**Yang berubah.** 4 file tema + `app_theme.dart` + 19 file presentation +
`app.dart`. Tidak ada satu pun susunan layar yang berubah — hanya nilai.

**Catatan pelaksanaan.** Kerjakan per file, jangan `sed` seluruh repo:
`outline` dan `labelSm` masing-masing punya dua tujuan yang hanya bisa
dibedakan dengan membaca konteksnya.

- **Tes:** tidak ada tes baru. `flutter analyze` + 173 tes lama tetap hijau
  adalah buktinya; tes yang mengunci nilai warna justru harus dihindari.
- **Ukuran:** besar (mekanis).
- **Risiko:** setiap layar berubah rupa sekaligus. Verifikasi pemilik di HP
  wajib sebelum D2, karena sesudah ini semua pembandingnya berubah.

---

### D2 — Navigasi: Kasir jadi tab pertama, Dasbor dibuang

**Tujuan.** Empat tab **Kasir · Produk · Riwayat · Laporan**; Pengaturan pindah
ke ikon gear di app bar Laporan; `dashboard/` dihapus seluruhnya.

**Ke mana isi Dasbor pindah:**

| Bagian Dasbor | Rumah barunya |
|---|---|
| Angka omzet hari ini (`_RevenueCard`, `_StatsRow`) | Laporan, chip "Hari ini" (D8) |
| Grafik 7 hari (`_RevenueChart`) | **dibuang** — v2 mengganti grafik dengan laba kotor |
| `BackupReminder` | Pengaturan, sebagai `Notice` di atas kartu backup (D8) |
| Tombol "Mulai transaksi" | **dibuang** — Kasir sudah jadi tab pertama |
| `_RestockList` (sudah di-comment) | **dihapus** — chip "Perlu restok" di Produk (D6) |

**Konsekuensi teknis yang paling penting: umur `CartBloc`.** Sekarang Kasir
rute penuh dan `CartBloc` dibuat di dalam `CashierScreen`, jadi keranjang lahir
dan mati bersama layarnya. Begitu Kasir jadi `StatefulShellBranch`, pemilik
bisa pindah ke tab Produk di tengah transaksi dan kembali — kalau `CartBloc`
tetap dibuat di dalam layar, **keranjang akan kosong saat kembali**. Jadi
`CartBloc` naik ke atas `StatefulShellRoute` (provider di `main.dart` atau di
`builder` shell). Ini perubahan perilaku, bukan hanya pemindahan widget, dan
butuh tes bloc yang memastikan isi keranjang bertahan.

**Yang berubah.** `app_router.dart`, `app.dart` (ikon v2: `point_of_sale`,
`inventory_2_outlined`, `receipt_long_outlined`, `bar_chart`), `page_routes.dart`
(rute `dashboard` dan `perluRestok` dihapus, `mulaiTransaksi` jadi branch),
`main.dart`, hapus `lib/features/dashboard/`, hapus `low_stock_screen.dart`.

- **Tes:** satu tes bloc "keranjang bertahan saat pindah tab" (murni bloc,
  async nyata). Tes widget navigasi tidak dibuat — `StatefulShellRoute` butuh
  pump rute penuh dan akan tersandung masalah fake-async yang sama.
- **Ukuran:** sedang.
- **Risiko:** **tinggi** — satu-satunya langkah yang bisa membuat transaksi
  berjalan hilang. Uji manual: isi keranjang → pindah tab → kembali.

---

### D3 — PIN jadi bottom sheet

**Tujuan.** `PinGate.require` membuka `PinPad` sebagai `showModalBottomSheet`,
bukan `context.push` ke `PinVerifyScreen`. Alasan desain: konteks tidak hilang
— pemilik tetap melihat transaksi yang sedang di-void di belakang sheet.

**Yang berubah.** `pin_gate.dart` (satu-satunya pintu, jadi empat pemanggilnya
— void, restore, ubah harga/modal, laba — tidak perlu disentuh),
`pin_verify_screen.dart` jadi isi sheet, rute `verifikasiPin` dihapus,
`pin_pad.dart` disesuaikan token v2.

**Yang tidak boleh berubah:** jeda bertingkat setelah PIN salah berulang
(5s → 30s → 5 menit) dan semua aturan `PinRepository`. Sheet hanya mengganti
wadahnya. `PopScope(canPop: false)` saat sheet sedang memverifikasi, supaya
tombol kembali tidak membatalkan di tengah.

- **Tes:** 9 tes `pin_repository_impl_test.dart` yang ada harus tetap hijau
  tanpa diubah — kalau salah satu perlu diubah, berarti wadahnya ikut mengubah
  aturannya dan itu tanda bahaya.
- **Ukuran:** sedang.
- **Risiko:** sedang — PIN menjaga empat aksi merusak data.

---

### D4 — Kasir + PayBar + "Sering dibeli"

**Tujuan.** Layar Kasir sesuai `Kasir-html/Main.dc.html`: kotak cari + tombol
scan, chip kategori, kartu keranjang dengan stepper qty, daftar "Sering
dibeli", PayBar melayang di atas bottom nav.

**Ini satu-satunya langkah desain yang menyentuh lapisan data.** Keputusan
pemilik nomor 4 ("produk terlaris 30 hari") tidak bisa memakai yang sudah ada:
`ReportDao.getBestSellers` mengelompokkan berdasarkan
`transaction_items.productName` — **snapshot nama**, tanpa id dan tanpa harga —
sehingga hasilnya tidak bisa dimasukkan ke keranjang. Yang dibutuhkan query
baru yang mengelompokkan berdasarkan `productId` lalu join ke `products`,
mengembalikan baris produk utuh (harga, stok, aktif) 30 hari terakhir, limit 5.

Jadi D4 berisi: `ProductDao.watchFrequentProducts()` + method repository +
usecase + wiring DI + UI. Kalau nanti biayanya terasa tidak sepadan, pilihan
"daftar produk aktif biasa" masih satu baris jauhnya — tapi itu keputusan
pemilik, bukan keputusan saat menulis kode.

**Yang berubah.** `cashier_screen.dart` (dibongkar paling banyak di rencana
ini), `product_dao.dart`, `product_repository*`, usecase baru,
`injection_container.dart`. Komponen `CartRow`, `ProductRow`, `Chip`, `Field`,
`PayBar` lahir di sini; yang dipakai layar lain diangkat ke
`lib/core/widgets/` saat layar itu dikerjakan.

- **Tes:** query terlaris diuji di tes repository dengan async nyata (produk
  terjual 30 hari, produk terjual 40 hari lalu tidak ikut, transaksi void tidak
  dihitung, produk nonaktif tidak muncul). Stepper qty sudah punya tes di
  `cart_bloc_test.dart`.
- **Ukuran:** besar.
- **Risiko:** sedang-tinggi — ini layar yang dipakai ratusan kali sehari dan
  satu-satunya yang punya metrik waktu (PRD §1.5, ≤30 detik untuk 3 item).

---

### D5 — Pembayaran jadi layar sendiri + Struk

**Tujuan.** `Pembayaran-html/Bayar.dc.html`: total belanja, field uang
diterima, tombol cepat (Uang pas / 25.000 / 50.000 / 100.000), kembalian
besar, rincian item, tombol "Selesaikan transaksi". Lalu
`Transaksi selesai-html/Struk.dc.html`: `Notice` hijau berhasil, preview struk
mono 58mm, tombol Cetak + Bagikan PDF, "Transaksi baru".

Sekarang pembayaran adalah `_PaymentPanel` di dalam layar Kasir. Memisahnya
membuat Kasir muat untuk keranjang dan PayBar.

**Yang berubah.** `cashier_screen.dart` (panel dikeluarkan),
layar pembayaran baru, `receipt_preview_screen.dart`.

**Tombol cepat** adalah satu-satunya tambahan fungsi di langkah ini: nominal
tetap, plus "Uang pas" yang mengisi tepat sebesar total.

- **Tes:** hitung kembalian sudah teruji di `cart_bloc_test.dart`; tambah tes
  untuk pemetaan tombol cepat → nilai field (fungsi murni).
- **Ukuran:** sedang.
- **Risiko:** sedang — uang dan atomisitas simpan transaksi ada di jalur ini.
  Aturan `int` rupiah dan simpan-atomik tidak boleh tersentuh.

---

### D6 — Produk + Tambah produk

**Tujuan.** `Produk.dc.html`: cari + scan, chip `Semua / Perlu restok · N /
<kategori>`, baris produk dengan avatar inisial, badge `Stok menipis` / `Habis`,
tombol "Tambah produk" melayang. Lalu `ProdukForm.dc.html`: harga jual dan
modal berdampingan, baris laba kotor per pcs, catatan "Mengubah harga nanti
perlu PIN".

**Chip "Perlu restok · N"** menggantikan `LowStockScreen` (keputusan 7).
Penyaringannya memakai `lowStockProducts` yang **sudah ada di state** — tidak
ada query baru. Menyatu dengan filter kategori yang baru selesai: chip kategori
tetap hanya untuk kategori yang punya produk aktif (ADR-038).

**Yang berubah.** `product_list_screen.dart`, `product_form_screen.dart`,
`stock_sheet.dart` (jadi `Sheet` v2), hapus `low_stock_screen.dart`.

- **Tes:** filter chip jadi fungsi murni seperti `categoriesWithActiveProducts`
  dan diuji begitu. Tes widget form yang ada (3) harus tetap hijau.
- **Ukuran:** sedang.
- **Risiko:** rendah-sedang.

---

### D7 — Riwayat + Void sebagai sheet

**Tujuan.** `Riwayat.dc.html`: app bar tanpa ikon (keputusan 6), chip rentang
`Hari ini / Kemarin / 7 hari / Pilih tanggal`, judul bagian "Hari ini · N
transaksi" + jumlah void, baris transaksi dengan badge `Selesai` / `Void`.
Lalu `Void.dc.html`: detail transaksi di belakang, dan **satu sheet** berisi
ringkasan dampak void, chip alasan (`Salah input` / `Pembeli batal` /
`Lainnya`), PIN pad, dan tombol "Void transaksi".

**Ini menggabungkan dua langkah yang sekarang terpisah** (PIN dulu, lalu dialog
alasan). Memakai sheet PIN dari D3. Chip alasan menggantikan ketik bebas —
`Lainnya` tetap membuka field teks, karena `voidReason` wajib terisi dan
alasan di luar tiga pilihan itu harus tetap bisa dicatat.

**Chip "Kemarin"** adalah rentang baru: `ReportPeriod` tidak punya padanannya
dan memang tidak dipakai di sini — riwayat memfilter dengan `since`, bukan
preset laporan.

- **Tes:** pemetaan chip → rentang tanggal sebagai fungsi murni (termasuk
  "Kemarin" = satu hari kalender penuh, bukan 24 jam ke belakang — aturan yang
  sama dengan `ReportPeriod.rangeFrom`). Tes void di repository harus tetap
  hijau tanpa diubah.
- **Ukuran:** sedang-besar.
- **Risiko:** **tinggi** — void mengubah stok dan uang, dan di sinilah PIN
  betul-betul menjaga sesuatu.

---

### D8 — Laporan + Pengaturan

**Tujuan.** `Laporan.dc.html`: chip preset, `StatTile` omzet besar + laba kotor
+ jumlah transaksi, daftar "Terlaris", ringkasan "Perlu restok" dengan "Lihat
semua" ke Produk, dan ikon gear ke Pengaturan. Lalu `Pengaturan.dc.html`:
`Notice` pengingat backup di atas, kartu Backup & restore, bagian Toko.

Laporan menerima warisan Dasbor (angka hari ini); Pengaturan menerima
`BackupReminder`. Chip "Pilih" (rentang bebas) **tidak dibangun** — PRD §3.2
memotongnya dan `ReportPeriod` sengaja tidak punya rentang bebas.

**Baris dummy "Pajak (PPN) 11%" dan "Printer thermal BT-01"** di Pengaturan
dihapus di sini — keduanya di luar scope (AGENTS.md §6) dan sudah lama jadi
utang.

**Laba kotor di-PIN?** PRD §1.6 menyebut "lihat laba" sebagai aksi ber-PIN, dan
mockup memberi ikon gembok kecil di `StatTile` laba. Perilaku sekarang: laba
tampil tanpa PIN. Ini **pertanyaan terbuka yang harus dijawab saat D8 dimulai**,
bukan diputuskan sendiri.

- **Tes:** 13 tes repository laporan sudah menjaga angkanya; tidak ada tes
  baru selain kalau laba jadi ber-PIN.
- **Ukuran:** sedang.
- **Risiko:** rendah.

---

### D9 — Sapu bersih

**Tujuan.** Sisa yang hanya bisa dilihat setelah semua layar jadi: token yang
ternyata tidak terpakai, `fontFeatures` yang terlewat di angka uang, ikon yang
masih campur filled dan outlined dalam satu layar, dan `test/widget_test.dart`
template counter yang sejak dulu membuat `flutter test` tanpa argumen gagal.

- **Ukuran:** kecil.
- **Risiko:** rendah.

---

## Yang **tidak** dikerjakan

- **Mode gelap.** v2 hanya satu tema (Terang), sesuai README-nya.
- **Rentang tanggal bebas** di Laporan (PRD §3.2).
- **Pencarian transaksi** di Riwayat (keputusan 6).
- **Jumlah produk/transaksi** di kartu backup (keputusan 5).
- **Gambar produk.** Skema `products` tidak punya kolomnya; v2 memakai kotak
  inisial justru karena itu.
- **Orientasi scanner.** Sudah selesai di luar rencana ini (ADR-043); v2 tidak
  menyebut orientasi sama sekali.
- **Cetak ESC/POS.** Tetap menunggu printer fisik (langkah 9). Baris "Printer:
  terhubung" di mockup Struk menampilkan label `PrinterService` yang sudah ada,
  bukan koneksi Bluetooth sungguhan.

---

## ADR yang akan lahir

Nomor bebas berikutnya **ADR-046** (ADR-038 sudah diambil tiket kategori,
ADR-045 sudah dipakai aturan hapus produk). Satu ADR per keputusan yang tidak
bisa disimpulkan dari kode:

- **Dasbor dibuang** dan ke mana tiap bagiannya pindah (D2).
- **`CartBloc` naik ke atas shell** — kenapa, dan apa yang rusak kalau
  diturunkan lagi (D2). Ini yang paling mudah dibatalkan tanpa sengaja.
- **PIN jadi sheet** dan batas yang tetap berlaku (D3).
- **Query terlaris kedua** di samping `getBestSellers`, dan kenapa yang lama
  tidak bisa dipakai untuk keranjang (D4).
- **`lib/core/widgets/`** sebagai rumah komponen design system (D3/D4).
- Kalau laba jadi ber-PIN: keputusan itu dan alasannya (D8).
