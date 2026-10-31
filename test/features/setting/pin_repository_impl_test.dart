import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/setting/data/repositories/pin_repository_impl.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';

import 'fake_secure_storage.dart';

void main() {
  const pin = '135790';
  const wrongPin = '000000';

  late FakeSecureStorage fake;
  late DateTime now;
  late PinRepositoryImpl repository;

  PinRepositoryImpl buildRepository() => PinRepositoryImpl(
    const FlutterSecureStorage(),
    now: () => now,
  );

  setUp(() {
    fake = FakeSecureStorage();
    FlutterSecureStoragePlatform.instance = fake;
    now = DateTime(2026, 1, 1, 8);
    repository = buildRepository();
  });

  group('buat & verifikasi', () {
    test('PIN benar diterima, PIN salah ditolak', () async {
      expect(await repository.hasPin(), const Right(false));

      expect(await repository.setPin(pin), const Right(null));
      expect(await repository.hasPin(), const Right(true));

      expect(await repository.verifyPin(pin), const Right(true));
      expect(await repository.verifyPin(wrongPin), const Right(false));
    });

    test('PIN tetap valid setelah app ditutup dan dibuka lagi', () async {
      await repository.setPin(pin);

      // Instance baru di atas isi storage yang sama = app dibuka ulang.
      final afterRestart = buildRepository();

      expect(await afterRestart.hasPin(), const Right(true));
      expect(await afterRestart.verifyPin(pin), const Right(true));
      expect(await afterRestart.verifyPin(wrongPin), const Right(false));
    });

    test('setPin menimpa PIN lama', () async {
      await repository.setPin(pin);
      await repository.setPin('246802');

      expect(await repository.verifyPin('246802'), const Right(true));
      expect(await repository.verifyPin(pin), const Right(false));
    });

    test('verifikasi sebelum PIN dibuat memberi NotFoundFailure', () async {
      final result = await repository.verifyPin(pin);
      expect(result.isLeft(), isTrue);
      expect(
        result.swap().getOrElse(() => const StorageFailure('')),
        isA<NotFoundFailure>(),
      );
    });
  });

  group('PIN tidak pernah tersimpan apa adanya', () {
    test('tidak ada nilai di storage yang memuat PIN', () async {
      await repository.setPin(pin);

      expect(fake.store, isNotEmpty);
      for (final entry in fake.store.entries) {
        expect(
          entry.value,
          isNot(contains(pin)),
          reason: 'PIN mentah bocor di key "${entry.key}"',
        );
      }
    });

    test('PIN tidak ada di database sama sekali (PRD §2.6)', () async {
      await repository.setPin(pin);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      for (final table in db.allTables) {
        // Tidak ada kolom yang disiapkan untuk menyimpan PIN...
        expect(
          table.$columns.map((c) => c.name.toLowerCase()),
          everyElement(isNot(contains('pin'))),
          reason: 'tabel ${table.actualTableName} punya kolom bernuansa PIN',
        );

        // ...dan tidak ada nilai tersimpan yang memuat PIN.
        final rows = await db.select(table).get();
        for (final row in rows) {
          expect(
            row.toString(),
            isNot(contains(pin)),
            reason: 'PIN bocor di tabel ${table.actualTableName}',
          );
        }
      }

      // Pembandingnya: PIN memang tersimpan, tapi hanya di secure storage.
      expect(fake.store.containsKey('pin_v1'), isTrue);
    });

    test('salt berbeda tiap kali, jadi hash PIN sama tidak kembar', () async {
      await repository.setPin(pin);
      final first = fake.store['pin_v1'];

      final secondFake = FakeSecureStorage();
      FlutterSecureStoragePlatform.instance = secondFake;
      await buildRepository().setPin(pin);
      final second = secondFake.store['pin_v1'];

      expect(first, isNotNull);
      expect(first, isNot(equals(second)));
    });
  });

  group('validasi', () {
    test('panjang selain ${PinRepository.pinLength} angka ditolak', () async {
      for (final invalid in ['', '1', '12345', '1234567']) {
        final result = await repository.setPin(invalid);
        expect(
          result.swap().getOrElse(() => const StorageFailure('')),
          isA<ValidationFailure>(),
          reason: 'PIN "$invalid" seharusnya ditolak',
        );
      }
    });

    test('PIN non-angka ditolak', () async {
      final result = await repository.setPin('12a456');
      expect(
        result.swap().getOrElse(() => const StorageFailure('')),
        isA<ValidationFailure>(),
      );
    });
  });

  group('jeda bertingkat setelah salah berulang', () {
    Future<Failure?> failureOf(Future<Either<Failure, bool>> call) async =>
        (await call).fold((failure) => failure, (_) => null);

    test('4 kali salah belum mengunci', () async {
      await repository.setPin(pin);

      for (var i = 0; i < 4; i++) {
        expect(await repository.verifyPin(wrongPin), const Right(false));
      }
      // percobaan ke-5 masih dilayani (bukan Left), baru setelahnya terkunci
      expect(await repository.verifyPin(pin), const Right(true));
    });

    test('salah ke-5 mengunci, dan terbuka sendiri setelah jedanya', () async {
      await repository.setPin(pin);
      for (var i = 0; i < 5; i++) {
        await repository.verifyPin(wrongPin);
      }

      final locked = await failureOf(repository.verifyPin(pin));
      expect(locked, isA<PinLockedFailure>());
      expect((locked! as PinLockedFailure).remaining.inSeconds, lessThanOrEqualTo(5));

      // PIN benar pun ditolak selama terkunci — ini inti proteksinya.
      now = now.add(const Duration(seconds: 6));
      expect(await repository.verifyPin(pin), const Right(true));
    });

    test('jeda naik: 5s lalu 30s lalu 5 menit', () async {
      await repository.setPin(pin);

      // Percobaan yang memasang kunci masih dilayani; kuncinya baru terasa di
      // percobaan sesudahnya. Jadi "amati" selalu satu panggilan terpisah.
      Future<Duration?> observeLock() async {
        final failure = await failureOf(repository.verifyPin(pin));
        return failure is PinLockedFailure ? failure.remaining : null;
      }

      Future<void> failOnce() async {
        await repository.verifyPin(wrongPin);
      }

      for (var i = 0; i < 5; i++) {
        await failOnce(); // gagal 1..5 — yang ke-5 memasang jeda 5s
      }
      expect(await observeLock(), const Duration(seconds: 5));

      now = now.add(const Duration(seconds: 6));
      await failOnce(); // gagal 6 — masih 5s
      now = now.add(const Duration(seconds: 6));
      await failOnce(); // gagal 7 — naik ke 30s
      expect(await observeLock(), const Duration(seconds: 30));

      now = now.add(const Duration(seconds: 31));
      await failOnce(); // gagal 8 — masih 30s
      now = now.add(const Duration(seconds: 31));
      await failOnce(); // gagal 9 — naik ke 5 menit
      expect(await observeLock(), const Duration(minutes: 5));
    });

    test('PIN benar mereset hitungan gagal', () async {
      await repository.setPin(pin);
      for (var i = 0; i < 4; i++) {
        await repository.verifyPin(wrongPin);
      }
      expect(await repository.verifyPin(pin), const Right(true));

      // hitungan sudah nol lagi: 4 kali salah berikutnya tetap belum mengunci
      for (var i = 0; i < 4; i++) {
        expect(await repository.verifyPin(wrongPin), const Right(false));
      }
      expect(await repository.lockoutRemaining(), const Right(null));
    });
  });
}
