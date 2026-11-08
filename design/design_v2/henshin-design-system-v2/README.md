# Henshin — design system v2

Henshin adalah kasir offline untuk satu warung, satu HP, satu pemegang PIN. Design system ini dibuat ulang dari v1 dengan satu tujuan: **lebih sedikit, lebih jelas, dan hanya untuk lima fitur di PRD** — Transaksi & Struk (F1), Produk & Stok (F2), Riwayat & Void (F3), Laporan (F4), Backup & Restore (F5).

Penggunanya pemilik toko dan kasir dari keluarga pemilik, di HP Android, sambil melayani pembeli. Setiap keputusan desain diuji dengan satu pertanyaan: *apakah ini membuat transaksi 3 item selesai di bawah 30 detik?*

## Apa yang berubah dari v1

| v1 | v2 | Alasan |
|---|---|---|
| 50+ token warna Material 3 (primary/secondary/tertiary/fixed/container…) | **17 token semantik** (`bg`, `surface`, `ink`, `primary`, 3 status × 2) | Di kode hanya ~10 token v1 yang benar-benar dipakai; `tertiary*`, `secondaryFixed*`, `primaryFixed*` dipakai 1–2 kali atau tidak sama sekali. |
| DESIGN.md bilang teal, mockup `design/*.png` biru + tombol hitam | **Teal `primary` di semua tempat** | Satu warna aksi, satu arti. |
| 24 warna hardcode (`Colors.black54`, `Colors.white70`…) dan 14 `fontSize` manual | Semua lewat token | Hardcode adalah sumber ketidakkonsistenan terbesar. |
| Inter di `AppTextStyle`, tapi tidak didaftarkan di `pubspec.yaml` (jadi tidak pernah tampil) | **Roboto bawaan Android** | Nol aset, nol setup, dan memang itulah yang sekarang tampil di HP. |
| Panduan tablet, split-screen 380px, grid 4–5 kolom, gambar produk | **HP saja, satu kolom, daftar** | PRD: satu perangkat Android. Produk tidak punya gambar di skema data. |
| Tombol "Diskon", `discountBadge`, status "Diproses" | Dihapus | Diskon di luar scope (PRD 1.4). Transaksi hanya Selesai atau Void. |
| Bayangan di setiap kartu, scale 98% saat tekan | **Garis `line`, tanpa bayangan**; bayangan hanya untuk sheet | Lebih sederhana dan lebih tegas di layar terang toko. |
| Dasbor dengan grafik 7 hari, "+12% vs kemarin", rata-rata, item terjual — tapi tanpa laba | **Laporan: omzet, laba kotor, jumlah transaksi, terlaris** | Persis US-4.1 dan US-4.2. Laba kotor adalah angka yang paling dicari pemilik. |

## Prinsip

1. **Satu aksi utama per layar.** Hanya satu tombol `primary` yang terlihat: *Bayar* di kasir, *Simpan* di form, *Buat backup* di pengaturan. Sisanya tombol sekunder atau ghost.
2. **Angka adalah isi.** Harga, total, dan kembalian memakai `body-strong`, `stat`, atau `amount` dengan angka tabular, rata kanan, format `Rp 18.000` dari `formatRupiah`. Tidak pernah desimal.
3. **Warna berarti status, bukan hiasan.** Hijau = Selesai/berhasil, kuning = Stok menipis/pengingat, merah = Void/Habis/error. Selalu ditemani teks — jangan pernah warna saja.
4. **Jempol dulu.** Semua yang bisa disentuh minimal `tap-min` (48px). Aksi yang diulang terus (Bayar, scan, +/−) ada di setengah bawah layar.
5. **Tidak ada yang hilang diam-diam.** Void, hapus, dan restore selalu lewat PIN + konfirmasi, dan hasilnya tetap terlihat (transaksi void tetap di riwayat dengan badge).

## Fondasi visual

**Warna.** Halaman `bg`, isi di atas `surface` putih, dipisah `line`. Teks `ink`, info sekunder `ink-muted`. `primary` (teal #006565, warisan v1) hanya untuk aksi dan keadaan aktif. Status memakai pasangan `success`/`success-soft`, `warning`/`warning-soft`, `danger`/`danger-soft`: teks berwarna pekat di atas latar lembut. Semua teks lolos 4.5:1 di latar yang tertulis di catatan tokennya. Hanya satu tema (Terang): toko terang, dan mode gelap belum diminta.

**Tipografi.** Satu keluarga, Roboto. Sembilan gaya: `amount` dan `stat` untuk angka, `title` / `heading` / `body` / `body-strong` / `label` / `caption` untuk teks, `receipt` (mono) khusus preview struk. Tidak ada teks penting di bawah 14px; `caption` (12px) hanya untuk badge dan label tab.

**Ruang.** Lima langkah: 4, 8, 12, 16, 24. Margin tepi layar dan padding kartu `space-4`. Jarak antar bagian `space-6`.

**Bentuk.** `radius-md` (12px) untuk hampir semuanya. `radius-full` hanya untuk chip filter supaya tidak tertukar dengan tombol. `radius-lg` untuk sudut atas sheet.

**Kedalaman.** Datar. Kartu dan baris dibatasi `line`, bukan bayangan. `shadow-sheet` hanya untuk bottom sheet, dialog, dan PayBar.

## Ikon

Material Icons bawaan Flutter (`uses-material-design: true`), gaya **outlined**, 24px, warna `ink-muted` (aktif: `primary`). Jangan campur filled dan outlined di satu layar. Ikon yang dipakai:

| Arti | Ikon |
|---|---|
| Kasir | `point_of_sale` |
| Produk | `inventory_2_outlined` |
| Riwayat | `receipt_long_outlined` |
| Laporan | `bar_chart` |
| Pengaturan | `settings_outlined` |
| Scan barcode | `qr_code_scanner` |
| Cari | `search` |
| Tambah / kurangi | `add`, `remove` |
| Cetak struk | `print_outlined` |
| Backup / restore | `backup_outlined`, `restore` |
| Void | `block` |

Produk tidak punya gambar; pakai kotak inisial (huruf pertama nama, `surface-muted`, `radius-sm`).

## Navigasi

Empat tab di `BottomNav`: **Kasir · Produk · Riwayat · Laporan**. Kasir menjadi tab pertama dan layar pembuka, karena itulah yang dibuka kasir setiap kali ada pembeli (v1 menaruhnya di balik tombol di Dasbor). Pengaturan (PIN, info toko, backup) ada di ikon gear di app bar Laporan — pemilik yang membukanya, bukan kasir.

Layar yang butuh PIN (PRD 1.6): void, restore backup, ubah harga/modal, dan angka laba. PIN muncul sebagai sheet `PinPad`, bukan layar penuh, supaya konteks tidak hilang.

## Bahasa dan copy

- Bahasa Indonesia sehari-hari, kalimat pendek, tanpa tanda seru. "Stok tinggal 3", bukan "Perhatian! Stok hampir habis!".
- Pakai istilah dari glosarium `CONTEXT.md`: **Produk** (bukan item/barang), **Kategori**, **Void** (bukan hapus/refund), **Backup** (bukan export).
- Tombol diawali kata kerja: "Bayar", "Simpan produk", "Void transaksi", "Buat backup".
- Uang selalu `Rp 18.000` (spasi setelah Rp, titik ribuan, tanpa desimal).
- Waktu: "Hari ini, 14.32" / "Kemarin, 09.10" / "3 Okt, 16.05".

## Komponen

| Komponen | Fitur | Untuk |
|---|---|---|
| Button | semua | Aksi. Primary, secondary, ghost, danger. |
| Field | F1, F2, F5 | Input teks, uang, dan pencarian dengan tombol scan. |
| Chip | F2, F4 | Filter kategori dan preset rentang tanggal. |
| Badge | F2, F3 | Status: Selesai, Void, Stok menipis, Habis. |
| ProductRow | F1, F2 | Satu produk di daftar dan di hasil cari kasir. |
| CartRow | F1 | Satu baris keranjang dengan stepper qty. |
| PayBar | F1 | Total + tombol Bayar, menempel di bawah layar kasir. |
| StatTile | F4 | Omzet, laba kotor, jumlah transaksi. |
| Notice | F1, F5 | Pengingat backup, printer gagal, hasil berhasil. |
| PinPad | F3, F5 | Masukkan PIN untuk aksi yang dilindungi. |
| Sheet | F2, F3 | Bottom sheet: restok, alasan void, pilih printer. |
| Receipt | F1, F3 | Preview struk 58mm sebelum cetak / share PDF. |
| BottomNav | semua | Empat tab utama. |

## Untuk developer Flutter

Token di sini dipetakan ke kelas tema yang sudah ada, dengan isi yang lebih sedikit:

```dart
class AppColor {
  static const bg = Color(0xFFF4F6F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEAEFF0);
  static const line = Color(0xFFDDE4E4);
  static const lineStrong = Color(0xFF8A9697);
  static const ink = Color(0xFF172021);
  static const inkMuted = Color(0xFF5B6768);
  static const primary = Color(0xFF006565);
  static const primaryPressed = Color(0xFF004D4D);
  static const primarySoft = Color(0xFFDDF0EF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const success = Color(0xFF1D6B37);
  static const successSoft = Color(0xFFE2F2E7);
  static const warning = Color(0xFF7A4F00);
  static const warningSoft = Color(0xFFFCEFD2);
  static const danger = Color(0xFFB3261E);
  static const dangerSoft = Color(0xFFFBE3E0);
}
```

Migrasi dari v1: `onSurface` → `ink`, `onSurfaceVariant`/`outline` (sebagai teks) → `inkMuted`, `outlineVariant`/`divider` → `line`, `surface`/`background` → `bg`, `surfaceContainerLowest` → `surface`, `surfaceContainerLow`/`inputBackground` → `surfaceMuted`, `primaryContainer` → `primary`, `secondaryContainer` → `primarySoft`, `error` → `danger`, `errorContainer` → `dangerSoft`, `warningColor`/`tertiaryFixed` → `warningSoft`. Semua `Colors.*` di `lib/features` diganti token. `AppSpacing` jadi `s1/s2/s3/s4/s6`, `AppRadius` jadi `sm/md/lg/full`. Untuk angka uang, tambahkan `fontFeatures: [FontFeature.tabularFigures()]`.
