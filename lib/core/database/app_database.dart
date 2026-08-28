import 'package:drift/drift.dart';

part 'app_database.g.dart';

// ================= TABLES =================

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get price => integer()(); // simpan dalam rupiah utuh, hindari REAL
  IntColumn get stock => integer().withDefault(const Constant(0))();
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
  IntColumn get priceAtSale => integer()(); // snapshot harga saat transaksi
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

// ================= DATABASE =================

@DriftDatabase(
  tables: [
    Categories,
    Products,
    Transactions,
    TransactionItems,
    StockMovements,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // tambahkan migration di sini seiring bertambahnya schemaVersion
        },
      );
}