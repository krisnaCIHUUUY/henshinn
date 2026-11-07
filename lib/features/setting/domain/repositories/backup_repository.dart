import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';

/// Satu-satunya jaring pengaman data aplikasi ini (PRD §1.6). Export tidak
/// di-PIN; restore wajib PIN, karena ia menimpa data yang sedang dipakai
/// (PRD §2.7 + ADR-037).
abstract class BackupRepository {
  /// Membuat snapshot database lalu membuka share sheet. Mencatat
  /// `lastBackupAt` hanya kalau share sheet tidak dibatalkan.
  Future<Either<Failure, void>> exportAndShare();

  /// Menimpa database aktif dengan isi [backup] (langkah 14 / PRD §1.6).
  ///
  /// Memvalidasi dulu, menyimpan salinan pengaman, lalu **menutup koneksi
  /// database**. Setelah ini `Right`, semua DAO dan repository di get_it
  /// memegang koneksi mati: pemanggil wajib menutup aplikasi, bukan melanjutkan
  /// ke layar lain (ADR-039).
  ///
  /// PIN diminta oleh pemanggil, bukan di sini — lapisan ini tidak punya
  /// `BuildContext`.
  Future<Either<Failure, void>> restoreFrom(File backup);
}
