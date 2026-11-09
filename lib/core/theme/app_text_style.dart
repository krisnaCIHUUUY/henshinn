import 'package:flutter/material.dart';

/// Sembilan gaya teks desain v2, satu keluarga font.
///
/// `fontFamily` sengaja tidak diisi. v1 menulis `'Inter'` padahal Inter tidak
/// pernah didaftarkan di `pubspec.yaml`, jadi yang tampil di HP selama ini
/// Roboto bawaan Android — dan desain v2 memilih Roboto secara sadar. Mengisi
/// `fontFamily` lagi berarti menambah aset untuk hasil yang sama.
///
/// Gaya angka ([amount], [stat], [bodyStrong]) memakai angka tabular supaya
/// digit tidak bergeser saat nilainya berubah — total di kasir dan omzet di
/// laporan berubah terus di tempat yang sama.
class AppTextStyle {
  AppTextStyle._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Satu angka terpenting di layar: total bayar, omzet hari ini.
  static const TextStyle amount = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
    letterSpacing: -0.5,
    fontFeatures: _tabular,
  );

  /// Nilai di StatTile (laba kotor, jumlah transaksi) dan kembalian.
  static const TextStyle stat = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 28 / 22,
    fontFeatures: _tabular,
  );

  /// Judul layar di app bar. Satu per layar.
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
  );

  /// Judul bagian di dalam layar dan judul sheet.
  static const TextStyle heading = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 24 / 17,
  );

  /// Nama produk, isi field, teks umum. Ukuran minimum untuk yang harus
  /// dibaca kasir dengan cepat.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  /// Harga di baris produk dan keranjang, label tombol.
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    fontFeatures: _tabular,
  );

  /// Info sekunder di bawah nama produk, label field, label chip dan stat.
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
  );

  /// Badge dan label bottom nav **saja**. Jangan untuk informasi yang harus
  /// dibaca.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
  );

  /// Preview struk 58mm (32 karakter per baris). Hanya di komponen Receipt.
  static const TextStyle receipt = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
  );
}
