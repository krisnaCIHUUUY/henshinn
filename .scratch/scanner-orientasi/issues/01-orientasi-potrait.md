# Ubah orientasi halaman scan barcode ke potrait

Status: done
Type: task

Diminta pemilik repo 2026-11-02, dikerjakan 2026-11-08 atas permintaan ulang
pemilik. **Selesai dan diverifikasi pemilik di HP fisik 2026-11-08.**

## Keadaan sekarang

`lib/features/transaction/presentation/screens/barcode_scanner_screen.dart`
mengunci landscape di `initState` dan memulihkan potrait di `dispose`:

```dart
// Barcode 1D lebih mudah terbaca dalam orientasi lebar.
SystemChrome.setPreferredOrientations([
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
]);
```

Keputusan landscape ini **tidak tercatat di ADR mana pun**, hanya di komentar
satu baris itu. Alasannya: barcode 1D (garis vertikal) lebih mudah masuk frame
kalau framenya lebar.

## Yang perlu dikerjakan

1. Hapus blok `setPreferredOrientations` di `initState`. Blok pemulih di
   `dispose` ikut jadi tidak perlu — periksa dulu apakah ada layar lain yang
   mengandalkannya (saat dicek 2026-11-02, hanya layar ini yang menyentuh
   `SystemChrome`).
2. Periksa overlay-nya di potrait. Frame pemandu, posisi tombol lampu/ganti
   kamera, dan `BoxFit.cover` pada `MobileScanner` semua ditata saat layarnya
   lebar; di potrait frame bisa jadi terlalu sempit atau preview-nya terpotong
   di sisi yang salah.
3. Pertimbangkan memperlebar area deteksi (`scanWindow`) supaya barcode 1D
   tetap mudah masuk frame tanpa keuntungan orientasi lebar.
4. Catat ADR baru: potrait dipilih atas permintaan pemilik, dan alasan landscape
   yang lama (barcode 1D) secara sadar ditukar dengan kenyamanan memegang HP.

## Kenapa butuh mata manusia

Scanner belum pernah dijalankan di HP fisik sama sekali (utang teknis langkah 7),
dan ini perubahan yang hasilnya hanya kelihatan di kamera sungguhan. Emulator
tidak membuktikan apa pun di sini. Metrik PRD "produk masuk keranjang ≤2 detik"
juga belum pernah terukur, jadi ukur sekalian saat mengetesnya.

## Comments

**2026-11-08 — kode selesai, menunggu HP.** Keempat butir di atas dikerjakan:

1. Kunci landscape di `initState` diganti `DeviceOrientation.portraitUp`.
   Tidak dihapus total: tanpa kunci, HP yang dimiringkan akan memutar halaman
   scan, dan pemilik meminta potrait.
2. `dispose` sekarang `setPreferredOrientations(const [])`. Versi lama mengunci
   potrait di sini, yang — karena tidak ada layar lain menyentuh
   `SystemChrome` — membuat seluruh aplikasi terkunci potrait setelah scanner
   dibuka sekali. Cacat lama, ikut beres.
3. Overlay: frame jadi lebar-dan-pendek (0,85 × lebar layar, tinggi 0,55 ×
   lebar frame). Rumus lama (0,6 × lebar, 0,45 × tinggi) menghasilkan kotak
   menjulang tinggi di potrait — bentuk paling sulit untuk barcode 1D. Teks
   instruksi dipindah ke bawah frame; dulu dipaku `bottom: 24` dan bertumpuk
   dengan tombol "Selesai · N item" saat keranjang terisi.
4. `scanWindow` **tidak** dipakai — alasannya di ADR-043. Singkatnya:
   membatasi deteksi ke frame yang lebih kecil akan membuat scan lebih sulit
   daripada sekarang, padahal tujuannya sebaliknya.
5. ADR-043 ditulis di `docs/keputusan-arsitektur.md`.

Rotasi preview tidak butuh kode kompensasi: `mobile_scanner` membungkus
preview-nya sendiri di `RotatedBox` berdasarkan `DeviceOrientation.turns` dan
membalik ukuran texture untuk orientasi landscape (dokumentasi arsitektur
mobile_scanner, dibaca lewat context7).

**Yang masih butuh mata manusia** — tidak ada tes yang bisa menggantikannya:
apakah frame barunya terasa pas, apakah preview `BoxFit.cover` terpotong di
sisi yang salah di potrait, dan apakah barcode EAN-13 di kemasan besar masih
masuk frame tanpa menarik kamera terlalu jauh. Sekalian ukur metrik PRD
"produk masuk keranjang ≤2 detik" yang sampai sekarang belum pernah diukur.

**2026-11-08 — diverifikasi.** Potrait jalan di HP pemilik. Saat mengujinya
ketemu bug lain yang tidak berhubungan: produk yang barcodenya terdaftar tidak
ketemu saat di-scan, karena jalur simpan memangkas barcode sementara jalur cari
tidak. Diperbaiki terpisah — lihat ADR-044 dan `docs/progress.md`. Tiket ini
ditutup.
