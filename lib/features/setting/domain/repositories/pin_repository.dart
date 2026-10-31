import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';

/// PIN pemilik. Hash + salt disimpan di secure storage, tidak pernah di DB
/// (PRD §2.6) supaya file backup tidak membawa PIN (PRD §2.7).
abstract class PinRepository {
  /// Panjang PIN yang diterima — dipakai juga oleh layar untuk keypad.
  static const int pinLength = 6;

  Future<Either<Failure, bool>> hasPin();

  /// Menimpa PIN lama kalau sudah ada, dan mereset hitungan gagal.
  Future<Either<Failure, void>> setPin(String pin);

  /// `Right(true)` benar, `Right(false)` salah,
  /// `Left(PinLockedFailure)` masih dalam masa tunggu,
  /// `Left(NotFoundFailure)` PIN belum pernah dibuat.
  Future<Either<Failure, bool>> verifyPin(String pin);

  /// Sisa masa tunggu, `null` kalau sedang tidak terkunci. Dipakai layar
  /// verifikasi untuk menampilkan hitungan saat dibuka.
  Future<Either<Failure, Duration?>> lockoutRemaining();
}
