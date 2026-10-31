import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/pin_repository.dart';

class PinRepositoryImpl implements PinRepository {
  final FlutterSecureStorage _storage;
  final DateTime Function() _now;

  PinRepositoryImpl(this._storage, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  // Formatnya diberi versi supaya jumlah iterasi bisa dinaikkan nanti tanpa
  // mengunci pemilik keluar: hash lama tetap bisa diverifikasi.
  static const _keyPin = 'pin_v1';
  static const _keyFailedAttempts = 'pin_failed_attempts';
  static const _keyLockedUntil = 'pin_locked_until';

  static const _iterations = 100000;
  static const _saltBytes = 16;

  /// Percobaan ke-1..4 bebas; mulai ke-5 kena jeda yang naik bertingkat.
  static const _freeAttempts = 4;

  static Duration _lockoutFor(int failedAttempts) {
    if (failedAttempts <= _freeAttempts) return Duration.zero;
    return switch (failedAttempts - _freeAttempts) {
      1 || 2 => const Duration(seconds: 5),
      3 || 4 => const Duration(seconds: 30),
      _ => const Duration(minutes: 5),
    };
  }

  @override
  Future<Either<Failure, bool>> hasPin() async {
    try {
      return Right(await _storage.read(key: _keyPin) != null);
    } catch (e) {
      return Left(StorageFailure('Gagal membaca status PIN: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setPin(String pin) async {
    final invalid = _validate(pin);
    if (invalid != null) return Left(invalid);

    try {
      final salt = _randomSalt();
      final hash = await _deriveOffThread(pin, salt, _iterations);
      await _storage.write(
        key: _keyPin,
        value: [
          '1',
          '$_iterations',
          base64Encode(salt),
          base64Encode(hash),
        ].join(r'$'),
      );
      await _resetAttempts();
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Gagal menyimpan PIN: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String pin) async {
    try {
      final stored = await _storage.read(key: _keyPin);
      if (stored == null) {
        return const Left(NotFoundFailure('PIN belum dibuat'));
      }

      final remaining = await _readLockout();
      if (remaining != null) {
        return Left(
          PinLockedFailure(
            'Terlalu banyak PIN salah. Coba lagi dalam '
            '${_humanize(remaining)}.',
            remaining,
          ),
        );
      }

      final parts = stored.split(r'$');
      if (parts.length != 4 || parts.first != '1') {
        return const Left(StorageFailure('Data PIN rusak, buat PIN baru'));
      }
      final iterations = int.tryParse(parts[1]);
      if (iterations == null) {
        return const Left(StorageFailure('Data PIN rusak, buat PIN baru'));
      }

      final expected = base64Decode(parts[3]);
      final actual = await _deriveOffThread(
        pin,
        base64Decode(parts[2]),
        iterations,
      );

      if (_constantTimeEquals(expected, actual)) {
        await _resetAttempts();
        return const Right(true);
      }
      await _recordFailure();
      return const Right(false);
    } catch (e) {
      return Left(StorageFailure('Gagal memverifikasi PIN: $e'));
    }
  }

  @override
  Future<Either<Failure, Duration?>> lockoutRemaining() async {
    try {
      return Right(await _readLockout());
    } catch (e) {
      return Left(StorageFailure('Gagal membaca masa tunggu PIN: $e'));
    }
  }

  // ===== internal =====

  ValidationFailure? _validate(String pin) {
    if (pin.length != PinRepository.pinLength) {
      return ValidationFailure(
        'PIN harus ${PinRepository.pinLength} angka',
      );
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      return const ValidationFailure('PIN hanya boleh angka');
    }
    return null;
  }

  List<int> _randomSalt() {
    final random = Random.secure();
    return List<int>.generate(_saltBytes, (_) => random.nextInt(256));
  }

  /// 100k iterasi butuh ~1 detik di desktop dan beberapa detik di HP kelas
  /// menengah, jadi dijalankan di isolate lain supaya UI tidak membeku.
  static Future<List<int>> _deriveOffThread(
    String pin,
    List<int> salt,
    int iterations,
  ) {
    return compute(
      (args) => _derive(args.$1, args.$2, args.$3),
      (pin, salt, iterations),
    );
  }

  /// PBKDF2-HMAC-SHA256, satu blok (dkLen 32 byte). Paket `crypto` tidak
  /// menyediakan PBKDF2, jadi loop-nya ditulis manual.
  static List<int> _derive(String pin, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    // Blok pertama PBKDF2: HMAC(salt || INT_BE32(1))
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.of(block);
    for (var i = 1; i < iterations; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block[j];
      }
    }
    return result;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  Future<Duration?> _readLockout() async {
    final raw = await _storage.read(key: _keyLockedUntil);
    if (raw == null) return null;
    final until = DateTime.tryParse(raw);
    if (until == null) return null;
    final remaining = until.difference(_now());
    return remaining > Duration.zero ? remaining : null;
  }

  Future<void> _recordFailure() async {
    final attempts =
        (int.tryParse(await _storage.read(key: _keyFailedAttempts) ?? '') ?? 0) +
        1;
    await _storage.write(key: _keyFailedAttempts, value: '$attempts');

    final lockout = _lockoutFor(attempts);
    if (lockout > Duration.zero) {
      await _storage.write(
        key: _keyLockedUntil,
        value: _now().add(lockout).toIso8601String(),
      );
    }
  }

  Future<void> _resetAttempts() async {
    await _storage.delete(key: _keyFailedAttempts);
    await _storage.delete(key: _keyLockedUntil);
  }

  static String _humanize(Duration d) {
    if (d.inMinutes >= 1) return '${d.inMinutes + 1} menit';
    return '${d.inSeconds + 1} detik';
  }
}
