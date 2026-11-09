import 'dart:ui';

/// Palet desain v2: 17 token semantik, satu tema (Terang).
///
/// Turunan dari 52 `static const` Material 3 di v1, yang di kode hanya ~10
/// benar-benar dipakai. Nilai dan kontrasnya dari
/// `design/design_v2/henshin-design-system-v2/tokens.json` — ubah di sana
/// dulu, jangan di sini.
///
/// Aturan yang mudah dilanggar tanpa sadar:
/// - [line] dekoratif saja (pemisah baris, tepi kartu). Batas kontrol yang
///   harus terlihat memakai [lineStrong] — itu satu-satunya garis yang lolos
///   3:1 di atas [surface].
/// - Warna status selalu berpasangan: teks pekat ([success]/[warning]/
///   [danger]) di atas latar lembut (`*Soft`), dan **selalu ditemani teks** —
///   jangan pernah warna saja.
class AppColor {
  AppColor._();

  /// Latar halaman di semua layar.
  static const Color bg = Color(0xFFF4F6F6);

  /// Kartu, baris daftar, sheet, bottom nav, field.
  static const Color surface = Color(0xFFFFFFFF);

  /// Chip tidak aktif, tombol sekunder, stepper qty, tombol PIN pad.
  static const Color surfaceMuted = Color(0xFFEAEFF0);

  /// Pemisah dan tepi kartu. Dekoratif — bukan untuk batas kontrol.
  static const Color line = Color(0xFFDDE4E4);

  /// Batas field dan chip outline. Satu-satunya garis yang menandai kontrol.
  static const Color lineStrong = Color(0xFF8A9697);

  /// Teks utama: nama produk, harga, total, judul.
  static const Color ink = Color(0xFF172021);

  /// Teks sekunder: kategori, stok, waktu, label stat, placeholder.
  static const Color inkMuted = Color(0xFF5B6768);

  /// Satu aksi utama per layar, tab aktif, fokus field, harga di kasir.
  static const Color primary = Color(0xFF006565);
  static const Color primaryPressed = Color(0xFF004D4D);

  /// Chip aktif, latar tab aktif, baris keranjang yang baru ditambahkan.
  static const Color primarySoft = Color(0xFFDDF0EF);

  /// Teks dan ikon di atas [primary] atau [danger].
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Badge Selesai, kembalian, notice berhasil.
  static const Color success = Color(0xFF1D6B37);
  static const Color successSoft = Color(0xFFE2F2E7);

  /// Badge Stok menipis, notice pengingat backup.
  static const Color warning = Color(0xFF7A4F00);
  static const Color warningSoft = Color(0xFFFCEFD2);

  /// Void, hapus produk, stok habis, PIN salah, error field. Sebagai isi
  /// tombol hanya untuk konfirmasi akhir yang merusak data.
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerSoft = Color(0xFFFBE3E0);
}
