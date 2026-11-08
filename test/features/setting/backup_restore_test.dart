import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/settings_dao.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/setting/data/repositories/backup_repository_impl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart';

/// Restore menukar file database, jadi tes ini tidak bisa memakai
/// `NativeDatabase.memory()` seperti tes export: databasenya harus benar-benar
/// ada di disk supaya close + rename bisa diuji.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final now = DateTime(2026, 11, 7, 10, 15);

  late Directory dbDir;
  late Directory cacheDir;
  late File live;
  late AppDatabase db;
  late SettingsDao settingsDao;

  setUp(() async {
    dbDir = await Directory.systemTemp.createTemp('henshin-db');
    cacheDir = await Directory.systemTemp.createTemp('henshin-cache');
    live = File(p.join(dbDir.path, BackupRepositoryImpl.liveDatabaseFileName));
    db = AppDatabase(NativeDatabase(live));
    settingsDao = SettingsDao(db);
    await db.select(db.categories).get(); // paksa seed + tulis file
  });

  tearDown(() async {
    // Restore yang berhasil sudah menutup koneksinya sendiri.
    try {
      await db.close();
    } catch (_) {}
    for (final dir in [dbDir, cacheDir]) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  });

  BackupRepositoryImpl build() => BackupRepositoryImpl(
    db,
    settingsDao,
    outputDirectory: () async => cacheDir,
    databaseDirectory: () async => dbDir,
    share: (_) async => ShareResultStatus.success,
    now: () => now,
  );

  Future<void> addProduct(String name, {int stock = 7, int price = 25000}) {
    return db.into(db.products).insert(
      ProductsCompanion.insert(
        name: name,
        price: price,
        costPrice: const Value(15000),
        stock: Value(stock),
        categoryId: 1,
      ),
    );
  }

  /// File SQLite sah tapi bukan Henshin: dipakai untuk menguji cek tabel.
  File writeForeignDatabase(String name, {int userVersion = 4}) {
    final path = p.join(cacheDir.path, name);
    final other = sqlite3.open(path);
    other
      ..execute('CREATE TABLE catatan (isi TEXT)')
      ..execute('PRAGMA user_version = $userVersion');
    other.close();
    return File(path);
  }

  /// Backup Henshin yang skemanya berbeda dari aplikasi saat ini.
  File backupWithSchemaVersion(int version) {
    final path = p.join(cacheDir.path, 'skema-$version.sqlite');
    final other = sqlite3.open(path);
    for (final table in const [
      'categories',
      'products',
      'transactions',
      'transaction_items',
      'stock_movements',
      'settings',
    ]) {
      other.execute('CREATE TABLE $table (id INTEGER PRIMARY KEY)');
    }
    other.execute('PRAGMA user_version = $version');
    other.close();
    return File(path);
  }

  group('validasi', () {
    test('file yang tidak ada ditolak', () {
      final failure = BackupRepositoryImpl.validate(
        File(p.join(cacheDir.path, 'tidak-ada.sqlite')),
      );
      expect(failure, isA<StorageFailure>());
    });

    test('file teks biasa ditolak, bukan dianggap database', () {
      final file = File(p.join(cacheDir.path, 'catatan.txt'))
        ..writeAsStringSync('ini bukan database, ini daftar belanja');

      expect(
        BackupRepositoryImpl.validate(file),
        isA<ValidationFailure>(),
      );
    });

    test('file lebih pendek dari header SQLite ditolak tanpa error baca', () {
      final file = File(p.join(cacheDir.path, 'pendek.sqlite'))
        ..writeAsBytesSync([1, 2, 3]);

      expect(BackupRepositoryImpl.validate(file), isA<ValidationFailure>());
    });

    test('database SQLite lain ditolak karena tabelnya tidak lengkap', () {
      final failure = BackupRepositoryImpl.validate(
        writeForeignDatabase('kontak.sqlite'),
      );

      expect(failure, isA<ValidationFailure>());
      // Pesannya harus menyebut tabel yang hilang, supaya pemilik tahu bedanya
      // dengan "file rusak".
      expect(failure!.message, contains('products'));
    });

    test('backup dari aplikasi versi lebih baru ditolak', () {
      final failure = BackupRepositoryImpl.validate(
        backupWithSchemaVersion(99),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, contains('lebih baru'));
    });

    test('backup dari skema lebih tua diterima, migrasi yang menaikkannya', () {
      expect(BackupRepositoryImpl.validate(backupWithSchemaVersion(1)), isNull);
    });

    test('backup dari skema yang sama diterima', () async {
      final backup = await build().exportToFile();

      expect(BackupRepositoryImpl.validate(backup), isNull);
    });

    test('user_version 0 ditolak: itu database yang belum pernah dimigrasi',
        () {
      final failure = BackupRepositoryImpl.validate(
        backupWithSchemaVersion(0),
      );

      expect(failure, isA<ValidationFailure>());
    });
  });

  group('restore', () {
    // Ini metrik PRD untuk langkah 14: backup → hapus data → restore → identik.
    test('data kembali identik setelah dihapus lalu dipulihkan', () async {
      await addProduct('Kopi Susu', stock: 7, price: 18000);
      await addProduct('Teh Manis', stock: 3, price: 8000);
      final backup = await build().exportToFile();

      await db.delete(db.products).go();
      expect(await db.select(db.products).get(), isEmpty);

      final result = await build().restoreFrom(backup);
      expect(result.isRight(), isTrue);

      // Koneksi lama sudah ditutup restore; buka file aktif sebagai koneksi
      // baru, persis seperti aplikasi setelah dibuka ulang.
      final reopened = AppDatabase(NativeDatabase(live));
      addTearDown(reopened.close);
      final rows = await reopened.select(reopened.products).get();

      expect(rows.map((p) => p.name), ['Kopi Susu', 'Teh Manis']);
      expect(rows.map((p) => p.stock), [7, 3]);
      expect(rows.map((p) => p.price), [18000, 8000]);
    });

    test('salinan pengaman berisi data sebelum ditimpa', () async {
      await addProduct('Kopi Susu');
      final backup = await build().exportToFile();
      await db.delete(db.products).go();
      await addProduct('Produk yang akan hilang');

      await build().restoreFrom(backup);

      final safety = File(
        p.join(cacheDir.path, BackupRepositoryImpl.safetyCopyFileName),
      );
      expect(safety.existsSync(), isTrue);

      final rescued = AppDatabase(NativeDatabase(safety));
      addTearDown(rescued.close);
      expect(
        (await rescued.select(rescued.products).get()).map((p) => p.name),
        ['Produk yang akan hilang'],
      );
    });

    test('file tidak sah tidak menyentuh database aktif', () async {
      await addProduct('Kopi Susu');
      final sebelum = live.lengthSync();
      final sampah = File(p.join(cacheDir.path, 'sampah.txt'))
        ..writeAsStringSync('bukan database');

      final result = await build().restoreFrom(sampah);

      expect(result.isLeft(), isTrue);
      expect(live.lengthSync(), sebelum);
      // Koneksinya masih hidup: database tidak boleh ditutup kalau restore-nya
      // tidak pernah terjadi.
      expect(
        (await db.select(db.products).get()).map((p) => p.name),
        ['Kopi Susu'],
      );
    });

    test('file sementara `.restore` tidak ditinggal setelah berhasil', () async {
      final backup = await build().exportToFile();

      await build().restoreFrom(backup);

      expect(File('${live.path}.restore').existsSync(), isFalse);
    });

    test('wal dan shm milik database lama dibuang', () async {
      final backup = await build().exportToFile();
      // Dibuat manual: sqlite hanya menulis sidecar ini dalam mode WAL, tapi
      // kalau suatu saat mode itu dinyalakan, sisa file lama harus tetap hilang.
      File('${live.path}-wal').writeAsBytesSync([0]);
      File('${live.path}-shm').writeAsBytesSync([0]);

      await build().restoreFrom(backup);

      expect(File('${live.path}-wal').existsSync(), isFalse);
      expect(File('${live.path}-shm').existsSync(), isFalse);
    });
  });
}
