# Ubah orientasi halaman scan barcode ke potrait

Status: ready-for-human
Type: task

Diminta pemilik repo 2026-11-02: halaman scan barcode harus potrait, bukan
landscape. Pemilik menyatakan akan mengerjakannya nanti — jangan dikerjakan
tanpa diminta ulang.

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
