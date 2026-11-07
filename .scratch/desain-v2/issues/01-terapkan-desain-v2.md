# Terapkan desain UI v2

Status: ready-for-human
Type: task

Diminta pemilik 2026-11-07: `design/design_v2/` berisi desain UI baru lengkap
(design system + sembilan layar). Pemilik minta **dikerjakan nanti** — tiket ini
hanya merekam apa isinya dan apa yang akan tersentuh, bukan izin mulai.

## Apa yang ada di folder itu

- `henshin-design-system-v2/` — `tokens.json` + `tokens.css`, `README.md`
  (prinsip, pemetaan token v1 → v2), dan 14 komponen dengan `README.md` +
  `preview.html` + PNG: Button, Field, Chip, Badge, ProductRow, CartRow,
  PayBar, StatTile, Notice, PinPad, Sheet, Receipt, BottomNav, Cover.
- Sembilan layar sebagai mockup HTML (React, `*.dc.html`): Kasir, Pembayaran,
  Transaksi selesai, Produk, Tambah produk, Riwayat, Void dengan PIN, Laporan,
  Pengaturan & Backup. README tiap folder menegaskan: **referensi, bukan kode
  produksi** — nilai desain ada di atribut `style="…"` dan blok `<helmet><style>`.

## Yang bukan sekadar ganti warna

Urutan di bawah dari yang paling berisiko. Nomor 1 dan 2 mengubah struktur,
bukan tampilan — keduanya butuh keputusan pemilik sebelum satu baris ditulis.

1. **Dasbor hilang, Kasir jadi tab pertama.** Navigasi v2 adalah empat tab
   **Kasir · Produk · Riwayat · Laporan**, dan Pengaturan pindah ke ikon gear di
   app bar Laporan. Sekarang `lib/app.dart:36-39` memakai Dasbor · Produk ·
   Riwayat · Pengaturan, dan Kasir ada di balik tombol di Dasbor. Artinya
   `dashboard_screen.dart` dibongkar: `BackupReminder` dan angka hari ini harus
   pindah rumah, dan `StatefulShellBranch` di `app_router.dart` berubah. Tidak
   ada mockup Dasbor di folder itu — konfirmasi dulu bahwa layar itu memang
   dibuang, bukan belum digambar.
2. **PIN jadi bottom sheet, bukan layar penuh.** v2 memakai komponen `PinPad`
   sebagai sheet "supaya konteks tidak hilang". Sekarang PIN adalah layar lewat
   `pin_gate.dart`. Ini mengubah alur, bukan gaya.
3. **Rename token massal.** `AppSpacing` jadi `s1/s2/s3/s4/s6` (sekarang
   `xs/sm/md/lg/xl/xxl/xxxl` + `unit`/`gutter`/`containerPadding`), `AppRadius`
   jadi `sm/md/lg/full` (sekarang juga punya `_default`/`xl` dan varian
   `*All`), dan `AppColor` turun dari 52 `static const` ke 17 token semantik.
   README v2 sudah memuat tabel pemetaan v1 → v2 yang lengkap — pakai itu,
   jangan tebak. Nilai angkanya juga berubah (mis. `radius-sm` 8px vs 4px
   sekarang), jadi ini bukan rename murni.
4. **23 `Colors.*` hardcode di `lib/features/`** harus diganti token.
5. **Font.** v1 menyebut Inter di `AppTextStyle` tapi tidak pernah didaftarkan
   di `pubspec.yaml`, jadi yang tampil selama ini Roboto. v2 memilih Roboto
   secara sadar — jadi ini cuma membetulkan dokumen, bukan menambah aset.
6. **Angka uang** dapat `fontFeatures: [FontFeature.tabularFigures()]`.
7. **Ikon bottom nav** ganti ke set outlined v2 (`point_of_sale`,
   `inventory_2_outlined`, `receipt_long_outlined`, `bar_chart`).

## Tabrakan dengan pekerjaan yang belum selesai

- **Langkah 14–15 belum ada.** Mockup "Pengaturan & Backup" sudah memuat
  **Restore**, dan "Void dengan PIN" sudah jadi layar sendiri. Restore baru
  dibangun di langkah 14. Menerapkan desain lebih dulu berarti membuat UI untuk
  fitur yang belum ada.
- **Kategori.** v2 memakai `Chip` sebagai filter kategori di layar Produk —
  itu persis yang diparkir di `.scratch/kategori-produk/issues/01-buat-kategori-dari-form-produk.md`.
  Kalau kategori dikerjakan setelah desain, chip-nya akan dibangun dua kali.
- **Orientasi scanner.** v2 menaruh scan di dalam `Field` dan tidak menyebut
  orientasi, jadi `.scratch/scanner-orientasi/issues/01-orientasi-potrait.md`
  tetap pertanyaan terbuka, bukan terjawab oleh desain ini.

## Yang sudah cocok, tidak perlu kerja tambahan

- `laba kotor` sudah ada: `SalesReport.grossProfit`
  (`lib/features/report/domain/entities/sales_report.dart:67`), jadi `StatTile`
  laba di Laporan tidak butuh query baru.
- `primary` v2 (`#006565`) adalah warna teal yang sama dengan v1.
- v2 hanya satu tema (Terang) — tidak ada mode gelap yang perlu dibangun.

## Pertanyaan terbuka untuk pemilik

1. Dasbor benar-benar dibuang? (lihat poin 1)
2. Urutannya: desain v2 dulu, atau langkah 14–15 dan kategori dulu lalu desain
   sekali jalan? Rekomendasi: **selesaikan langkah 14–15 dulu**, supaya desain
   diterapkan ke aplikasi yang fiturnya sudah lengkap dan tidak ada layar yang
   digambar dua kali.
3. Sekali besar atau bertahap per layar? Rename token (poin 3) tidak bisa
   bertahap — ia menyentuh hampir semua file `lib/features/` sekaligus.

## Catatan

Perubahan ini akan melahirkan ADR baru (nomor bebas berikutnya **ADR-038** di
`docs/keputusan-arsitektur.md`, **bukan** `docs/adr/`): setidaknya satu untuk
pembuangan Dasbor dan satu untuk PIN-sebagai-sheet. Nomor ADR-038 juga
diperebutkan tiket kategori — siapa pun yang jalan lebih dulu mengambil 038.
