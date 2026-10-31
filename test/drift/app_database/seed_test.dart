import 'dart:io';

// `isNull` ada di drift dan di matcher — ambil versi matcher.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:path/path.dart' as p;

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('DB baru dapat kategori default + satu baris settings', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final categories = await db.select(db.categories).get();
    expect(categories.map((c) => c.name), [kDefaultCategoryName]);

    final settings = await db.select(db.settings).get();
    expect(settings, hasLength(1));
    expect(settings.single.schemaVersion, db.schemaVersion);
    expect(settings.single.lastBackupAt, isNull);
  });

  test('FK ditegakkan: produk tidak bisa menunjuk kategori yang tidak ada',
      () async {
    // Inilah yang membuat seed kategori ada gunanya. Tanpa
    // `PRAGMA foreign_keys = ON` SQLite menerima saja id kategori ngawur.
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await expectLater(
      db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(name: 'Orphan', price: 1000, categoryId: 999),
          ),
      throwsA(anything),
    );

    // kategori hasil seed tetap diterima
    final seeded = await db.select(db.categories).getSingle();
    await db
        .into(db.products)
        .insert(
          ProductsCompanion.insert(
            name: 'Sah',
            price: 1000,
            categoryId: seeded.id,
          ),
        );
    expect(await db.select(db.products).get(), hasLength(1));
  });

  test('seed tidak menduplikasi saat DB dibuka ulang', () async {
    // Pakai file, bukan memory: `beforeOpen` jalan setiap kali DB dibuka, dan
    // executor in-memory tidak bisa dibuka ulang setelah ditutup.
    final dir = Directory.systemTemp.createTempSync('henshin_seed_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'henshin.sqlite'));

    final first = AppDatabase(NativeDatabase(file));
    await first.select(first.categories).get(); // paksa beforeOpen
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);
    expect(await second.select(second.categories).get(), hasLength(1));
    expect(await second.select(second.settings).get(), hasLength(1));
  });

  test('DB v1 yang belum punya kategori ikut dapat seed saat upgrade', () async {
    // Inilah alasan seed memakai "kalau tabel kosong" dan bukan
    // `details.wasCreated`: install v1 lama tidak pernah lewat onCreate.
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    expect(await db.select(db.categories).get(), hasLength(1));
    expect(
      (await db.select(db.categories).getSingle()).name,
      kDefaultCategoryName,
    );
  });
}
