import 'package:drift/drift.dart';

import 'app_database.steps.dart';

part 'app_database.g.dart';

// ================= TABLES =================

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

// SQLite mengizinkan banyak NULL di index unik, jadi barcode tetap opsional
// tapi tidak boleh kembar (rencana langkah 4: "barcode nullable unik").
@TableIndex(name: 'products_barcode_unique', columns: {#barcode}, unique: true)
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get price => integer()(); // simpan dalam rupiah utuh, hindari REAL
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThreshold =>
      integer().withDefault(const Constant(5))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get categoryId =>
      integer().references(Categories, #id)();
  TextColumn get barcode => text().nullable()();
  TextColumn get imagePath => text().nullable()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  IntColumn get total => integer()();
  IntColumn get paymentAmount => integer()();
  IntColumn get change => integer()();
  // status: 'completed' | 'voided'
  TextColumn get status =>
      text().withDefault(const Constant('completed'))();
  TextColumn get voidReason => text().nullable()();
}

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId =>
      integer().references(Transactions, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get qty => integer()();
  // Snapshot saat transaksi (PRD §2.6): laporan lama tidak boleh berubah saat
  // nama atau harga produk diganti. Laba kotor dihitung dari dua kolom harga
  // di sini, bukan dari produk yang berlaku sekarang.
  TextColumn get productName => text().withDefault(const Constant(''))();
  IntColumn get priceAtSale => integer()();
  IntColumn get costPriceAtSale => integer().withDefault(const Constant(0))();
}

class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  // type: 'in' | 'out' | 'adjustment'
  TextColumn get type => text()();
  IntColumn get quantity =>
      integer()(); // positif untuk in/adjustment+, negatif untuk out/adjustment-
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Selalu tepat satu baris (id = 1). PIN tidak disimpan di sini — hash-nya
/// ada di secure storage (PRD §2.6).
class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get storeName => text().withDefault(const Constant(''))();
  TextColumn get storeAddress => text().withDefault(const Constant(''))();
  TextColumn get receiptMessage => text().withDefault(const Constant(''))();
  DateTimeColumn get lastBackupAt => dateTime().nullable()();
  // shortcut: hanya diisi saat seed, jadi basi setelah bump schemaVersion
  // berikutnya. Perbarui barisnya di step migrasi saat v3 dibuat, atau baca
  // `user_version` SQLite saja kalau validasi restore (langkah 14) butuh ini.
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ================= DATABASE =================

/// Dipakai saat seed agar FK `products.categoryId` tidak pernah orphan.
const kDefaultCategoryName = 'Umum';

@DriftDatabase(
  tables: [
    Categories,
    Products,
    Transactions,
    TransactionItems,
    StockMovements,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: _upgrade,
        beforeOpen: (details) async {
          // Tanpa pragma ini SQLite mengabaikan semua `references` di atas:
          // produk yang sudah dipakai transaksi bisa terhapus dan riwayat jadi
          // menggantung. Harus di luar `transaction()` — pragma tidak bisa
          // diubah dari dalam transaksi. onUpgrade sudah lewat di titik ini,
          // jadi migrasi tetap jalan dengan FK mati seperti default SQLite.
          await customStatement('PRAGMA foreign_keys = ON');

          // "kalau kosong", bukan `details.wasCreated`: device yang sudah
          // install v1 juga perlu kategori default + baris settings.
          await _seedIfEmpty();
        },
      );

  Future<void> _seedIfEmpty() async {
    await transaction(() async {
      final hasCategory =
          await (select(categories)..limit(1)).getSingleOrNull() != null;
      if (!hasCategory) {
        await into(categories).insert(
          CategoriesCompanion.insert(name: kDefaultCategoryName),
        );
      }

      final hasSettings =
          await (select(settings)..limit(1)).getSingleOrNull() != null;
      if (!hasSettings) {
        await into(settings).insert(
          SettingsCompanion.insert(schemaVersion: schemaVersion),
        );
      }
    });
  }
}

/// Di extension, bukan getter di `AppDatabase`: mencegah tiap step tanpa sengaja
/// memakai skema terkini alih-alih snapshot versinya sendiri (anjuran docs Drift).
extension _Migrations on GeneratedDatabase {
  OnUpgrade get _upgrade => stepByStep(
        from1To2: (m, schema) async {
          await m.addColumn(schema.products, schema.products.costPrice);
          await m.addColumn(
            schema.products,
            schema.products.lowStockThreshold,
          );
          await m.addColumn(schema.products, schema.products.isActive);
          await m.createTable(schema.settings);
        },
        from3To4: (m, schema) async {
          await m.addColumn(
            schema.transactionItems,
            schema.transactionItems.productName,
          );
          await m.addColumn(
            schema.transactionItems,
            schema.transactionItems.costPriceAtSale,
          );
        },
        from2To3: (m, schema) async {
          // Gagal kalau sudah ada barcode kembar di DB lama — memang harus
          // gagal: lebih baik ketahuan saat upgrade daripada stok salah pindah.
          await m.createIndex(schema.productsBarcodeUnique);
        },
      );
}