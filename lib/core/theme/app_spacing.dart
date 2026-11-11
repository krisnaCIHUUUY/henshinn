/// Jarak desain v2: lima langkah, bukan tujuh.
///
/// Namanya mengikuti `tokens.json` (`space-1` … `space-6`) supaya nilai di
/// desain dan di kode bisa dicocokkan tanpa tabel penerjemah. Tidak ada `s5`:
/// 20px tidak dipakai desain v2.
class AppSpacing {
  AppSpacing._();

  /// Jarak ikon ke teks, nama produk ke info di bawahnya.
  static const double s1 = 4;

  /// Gap antar chip, antar tombol PIN pad, padding badge horizontal.
  static const double s2 = 8;

  /// Padding vertikal baris daftar, gap antar StatTile.
  static const double s3 = 12;

  /// Margin tepi layar, padding kartu dan sheet. Default hampir semua padding.
  static const double s4 = 16;

  /// Jarak antar bagian di satu layar.
  static const double s6 = 24;

  /// Tinggi minimum semua yang bisa disentuh.
  static const double tapMin = 48;

  /// Tinggi tombol primary dan PayBar — aksi yang diulang ratusan kali sehari.
  static const double tapPrimary = 56;

  /// Tinggi minimum baris produk dan baris keranjang.
  static const double rowMin = 64;
}
