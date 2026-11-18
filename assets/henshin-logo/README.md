# Logo Henshin

Simbolnya huruf **H** yang dibentuk dari dua potong struk dengan tepi bawah sobek. Artinya: Henshin mengubah nota tulis tangan menjadi struk digital. Bentuknya diambil dari design system v2: warna `primary` (#006565), sudut tile 25% (sejalan dengan `radius-md`), dan motif struk yang juga dipakai di cover dan komponen Receipt.

## File

| File | Pakai untuk |
|---|---|
| `svg/henshin-app-icon.svg` | Ikon aplikasi: tile teal + H putih. Bentuk utama logo. |
| `svg/henshin-symbol.svg` | H saja, teal, tanpa latar. Untuk splash, header struk PDF, dan layar About. |
| `svg/henshin-symbol-white.svg` | H putih, untuk diletakkan di atas `primary` atau `ink`. |
| `svg/henshin-wordmark.svg` | Tulisan "Henshin" saja, warna `ink`. |
| `svg/henshin-lockup.svg` | Tile + tulisan, untuk latar terang (`bg`, `surface`). |
| `svg/henshin-lockup-white.svg` | Tile putih + tulisan putih, untuk latar `primary`. |
| `png/` | Versi PNG: ikon 256/512/1024, lockup, dan ikon Play Store 512 (kotak penuh tanpa sudut, karena Play Store memasang mask sendiri). |
| `android/res/` | Siap disalin ke `android/app/src/main/res/` di proyek Flutter. |

## Pasang ikon di aplikasi Flutter

1. Salin isi `android/res/` ke `android/app/src/main/res/` dan timpa `ic_launcher.png` bawaan Flutter.
2. Tidak perlu mengubah `AndroidManifest.xml`, karena `android:icon="@mipmap/ic_launcher"` sudah benar.
3. Android 8 ke atas memakai ikon adaptif (`mipmap-anydpi-v26/ic_launcher.xml`): latar teal `#006565` dan H putih di zona aman 66dp, jadi tidak terpotong mask lingkaran, kotak, atau squircle. Android 13 ke atas juga mendapat ikon monokrom untuk themed icons.
4. Ganti label aplikasi di manifest dari `henshin` menjadi `Henshin`.

## Aturan pakai

- **Warna hanya dua kombinasi:** H putih di atas teal, atau H teal di atas terang. Jangan pakai warna status (hijau, kuning, merah) dan jangan pakai gradasi.
- **Ruang kosong** di sekitar logo minimal selebar satu potongan struk (≈ 37% lebar H).
- **Ukuran minimum:** ikon 24px, lockup tinggi 32px.
- **Jangan:** memutar, merenggangkan, menambah bayangan, mengganti tepi sobek dengan garis lurus, atau mengetik ulang wordmark dengan font lain.
- **Wordmark** memakai Inter Display Bold yang sudah diubah menjadi kurva, jadi tidak butuh font terpasang. Teks UI aplikasi tetap memakai Roboto sesuai design system.
