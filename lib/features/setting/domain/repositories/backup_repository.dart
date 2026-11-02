import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';

/// Satu-satunya jaring pengaman data aplikasi ini (PRD §1.6). Tidak di-PIN:
/// PRD §2.7 hanya mewajibkan PIN untuk void, restore, dan ubah harga/modal.
abstract class BackupRepository {
  /// Membuat snapshot database lalu membuka share sheet. Mencatat
  /// `lastBackupAt` hanya kalau share sheet tidak dibatalkan.
  Future<Either<Failure, void>> exportAndShare();
}
