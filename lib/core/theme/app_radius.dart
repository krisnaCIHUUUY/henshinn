import 'package:flutter/material.dart';

/// Radius desain v2: empat nilai.
///
/// Nilainya berubah dari v1, bukan hanya namanya: `sm` 4 → 8 dan `lg` 16 → 20.
/// Varian `*All` tetap ada karena Flutter menuntut `BorderRadius`, bukan
/// `double`, di hampir semua tempat.
class AppRadius {
  AppRadius._();

  /// Badge, avatar inisial produk, tombol stepper.
  static const double sm = 8;

  /// Tombol, field, kartu, StatTile, notice. Default.
  static const double md = 12;

  /// Sudut atas bottom sheet.
  static const double lg = 20;

  /// Chip filter saja, supaya tidak tertukar dengan tombol.
  static const double full = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  // `lgAll` dihapus di D9: setelah semua layar jadi v2, satu-satunya tempat
  // radius 20 dipakai adalah sudut atas sheet — `sheetTop` di bawah. `lg`
  // sendiri tetap, karena itu sumber nilainya.
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));

  /// Sheet hanya membulat di atas.
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
}
