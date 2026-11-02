import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/settings_dao.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/setting/data/repositories/backup_repository_impl.dart';
import 'package:henshin/features/setting/domain/entities/store_info.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final now = DateTime(2026, 11, 2, 14, 30);

  late AppDatabase db;
  late SettingsDao settingsDao;
  late Directory outDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settingsDao = SettingsDao(db);
    outDir = await Directory.systemTemp.createTemp('henshin-backup-test');
    await db.select(db.categories).get(); // paksa seed
  });

  tearDown(() async {
    await db.close();
    if (outDir.existsSync()) outDir.deleteSync(recursive: true);
  });

  BackupRepositoryImpl build({
    ShareBackup? share,
    DateTime Function()? clock,
    Future<Directory> Function()? dir,
  }) => BackupRepositoryImpl(
    db,
    settingsDao,
    outputDirectory: dir ?? () async => outDir,
    share: share ?? (_) async => ShareResultStatus.success,
    now: clock ?? () => now,
  );

  Future<void> addProduct(String name, {int stock = 7}) async {
    await db
        .into(db.products)
        .insert(
          ProductsCompanion.insert(
            name: name,
            price: 25000,
            costPrice: const Value(15000),
            stock: Value(stock),
            categoryId: 1,
          ),
        );
  }

  group('snapshot', () {
    test('file hasil export benar-benar database SQLite', () async {
      await addProduct('Kopi');

      final file = await build().exportToFile();

      expect(file.existsSync(), isTrue);
      // Byte 0..14 file SQLite selalu penanda ini (byte ke-16 adalah NUL).
      // Kalau VACUUM INTO gagal separuh jalan, file-nya ada tapi header-nya
      // bukan ini.
      final header = await file.openRead(0, 15).first;
      expect(String.fromCharCodes(header), 'SQLite format 3');
    });

    test('isi snapshot identik dengan data aslinya', () async {
      await addProduct('Kopi', stock: 7);
      await addProduct('Teh', stock: 3);

      final file = await build().exportToFile();

      final restored = AppDatabase(NativeDatabase(file));
      addTearDown(restored.close);
      final rows = await restored.select(restored.products).get();

      expect(rows.map((p) => p.name), ['Kopi', 'Teh']);
      expect(rows.map((p) => p.stock), [7, 3]);
    });

    test('perubahan setelah export tidak ikut masuk snapshot', () async {
      await addProduct('Kopi');
      final file = await build().exportToFile();

      await addProduct('Teh'); // setelah snapshot diambil

      final restored = AppDatabase(NativeDatabase(file));
      addTearDown(restored.close);
      expect(
        (await restored.select(restored.products).get()).map((p) => p.name),
        ['Kopi'],
      );
    });

    test('nama file memuat tanggal dan jam', () async {
      final file = await build().exportToFile();
      expect(
        file.uri.pathSegments.last,
        'henshin-backup-2026-11-02-1430.sqlite',
      );
    });

    test('export kedua di jam berbeda tidak menimpa yang pertama', () async {
      final pertama = await build().exportToFile();
      final kedua = await build(
        clock: () => DateTime(2026, 11, 2, 16, 5),
      ).exportToFile();

      expect(pertama.path, isNot(kedua.path));
      expect(pertama.existsSync(), isTrue);
      expect(kedua.existsSync(), isTrue);
    });

    test('export ulang di jam yang sama menimpa file lama, bukan gagal',
        () async {
      await build().exportToFile();
      // sqlite menolak VACUUM INTO ke file yang sudah ada, jadi tanpa
      // deleteSync() di exportInto panggilan kedua ini melempar.
      final kedua = await build().exportToFile();
      expect(kedua.existsSync(), isTrue);
    });
  });

  group('lastBackupAt', () {
    test('dicatat setelah share berhasil', () async {
      expect((await settingsDao.getSettings()).lastBackupAt, isNull);

      final result = await build().exportAndShare();

      expect(result.isRight(), isTrue);
      expect((await settingsDao.getSettings()).lastBackupAt, now);
    });

    test('tidak dicatat kalau share sheet dibatalkan', () async {
      final result = await build(
        share: (_) async => ShareResultStatus.dismissed,
      ).exportAndShare();

      // Bukan error: user memang memilih tidak mengirim ke mana pun.
      expect(result.isRight(), isTrue);
      expect((await settingsDao.getSettings()).lastBackupAt, isNull);
    });

    test('dicatat walau Android tidak bisa melaporkan hasil share', () async {
      await build(
        share: (_) async => ShareResultStatus.unavailable,
      ).exportAndShare();

      expect((await settingsDao.getSettings()).lastBackupAt, now);
    });

    test('export gagal memberi StorageFailure dan tidak mencatat apa pun',
        () async {
      final result = await build(
        dir: () async => throw const FileSystemException('tidak ada ruang'),
      ).exportAndShare();

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<StorageFailure>()), (_) {});
      expect((await settingsDao.getSettings()).lastBackupAt, isNull);
    });
  });

  group('ambang pengingat', () {
    StoreInfo withBackup(DateTime? at) => StoreInfo(lastBackupAt: at);

    test('belum pernah backup dianggap basi', () {
      expect(withBackup(null).backupIsStale(now), isTrue);
      expect(withBackup(null).daysSinceBackup(now), isNull);
    });

    test('tepat 7 hari belum basi, 8 hari basi', () {
      expect(
        withBackup(now.subtract(const Duration(days: 7))).backupIsStale(now),
        isFalse,
      );
      expect(
        withBackup(now.subtract(const Duration(days: 8))).backupIsStale(now),
        isTrue,
      );
    });

    test('dihitung per hari kalender, bukan per 168 jam', () {
      // Backup jam 23:00, dibuka jam 01:00 delapan hari kemudian: selisih jam
      // 169 (jatuh di hari ke-8 kalender), jadi harus sudah basi.
      final store = withBackup(DateTime(2026, 10, 25, 23));
      expect(store.daysSinceBackup(DateTime(2026, 11, 2, 1)), 8);
      expect(store.backupIsStale(DateTime(2026, 11, 2, 1)), isTrue);
    });

    test('backup hari ini tidak basi', () {
      expect(withBackup(now).daysSinceBackup(now), 0);
      expect(withBackup(now).backupIsStale(now), isFalse);
    });
  });
}
