import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/category_dao.dart';
import 'package:henshin/core/database/dao/product_dao.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/product/data/repositories/product_repository_impl.dart';
import 'package:henshin/features/product/domain/entities/product.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProductRepositoryImpl repository;

  const categoryId = 1; // 'Umum' hasil seed

  NewProduct draft({
    String name = 'Cappuccino',
    int stock = 10,
    int lowStockThreshold = 5,
    bool isActive = true,
  }) => NewProduct(
    name: name,
    price: 25000,
    costPrice: 15000,
    stock: stock,
    lowStockThreshold: lowStockThreshold,
    isActive: isActive,
    categoryId: categoryId,
  );

  Failure? failureOf(dynamic either) =>
      either.fold((Failure f) => f, (_) => null);

  Future<List<StockMovement>> ledgerOf(int productId) =>
      (db.select(db.stockMovements)
            ..where((m) => m.productId.equals(productId))
            ..orderBy([(m) => OrderingTerm.asc(m.id)]))
          .get();

  Future<int> stockOf(int productId) async =>
      (await (db.select(db.products)
                ..where((p) => p.id.equals(productId)))
              .getSingle())
          .stock;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = ProductRepositoryImpl(ProductDao(db), CategoryDao(db));
    await db.select(db.categories).get(); // paksa seed
  });

  tearDown(() => db.close());

  group('ledger stock_movements', () {
    test('restok +50 membuat stok dan ledger cocok', () async {
      final id = (await repository.addProduct(draft(stock: 10))).getOrElse(
        () => -1,
      );

      expect(failureOf(await repository.restock(id, 50, note: 'Nota 123')),
          isNull);

      expect(await stockOf(id), 60);

      final ledger = await ledgerOf(id);
      // baris 1 = stok awal, baris 2 = restok
      expect(ledger.map((m) => m.type), ['in', 'in']);
      expect(ledger.map((m) => m.quantity), [10, 50]);
      expect(ledger.last.note, 'Nota 123');

      // jumlah seluruh ledger harus sama dengan stok
      final total = ledger.fold<int>(0, (sum, m) => sum + m.quantity);
      expect(total, await stockOf(id));
    });

    test('stok awal 0 tidak membuat baris ledger kosong', () async {
      final id = (await repository.addProduct(draft(stock: 0))).getOrElse(
        () => -1,
      );
      expect(await ledgerOf(id), isEmpty);
    });

    test('koreksi mencatat selisih, bukan angka akhirnya', () async {
      final id = (await repository.addProduct(draft(stock: 10))).getOrElse(
        () => -1,
      );

      // hitung fisik ternyata 7 (selisih -3)
      await repository.adjustStock(id, 7, note: 'Hilang 3');
      expect(await stockOf(id), 7);

      final ledger = await ledgerOf(id);
      expect(ledger.last.type, 'adjustment');
      expect(ledger.last.quantity, -3);

      final total = ledger.fold<int>(0, (sum, m) => sum + m.quantity);
      expect(total, 7);
    });

    test('koreksi ke angka yang sama tidak menulis ledger', () async {
      final id = (await repository.addProduct(draft(stock: 10))).getOrElse(
        () => -1,
      );
      await repository.adjustStock(id, 10);
      expect(await ledgerOf(id), hasLength(1)); // hanya stok awal
    });

    test('restok 0 atau negatif ditolak, stok tidak berubah', () async {
      final id = (await repository.addProduct(draft(stock: 10))).getOrElse(
        () => -1,
      );

      for (final qty in [0, -5]) {
        expect(
          failureOf(await repository.restock(id, qty)),
          isA<ValidationFailure>(),
          reason: 'restok $qty seharusnya ditolak',
        );
      }
      expect(await stockOf(id), 10);
      expect(await ledgerOf(id), hasLength(1));
    });

    test('koreksi ke angka negatif ditolak', () async {
      final id = (await repository.addProduct(draft(stock: 10))).getOrElse(
        () => -1,
      );
      expect(
        failureOf(await repository.adjustStock(id, -1)),
        isA<ValidationFailure>(),
      );
      expect(await stockOf(id), 10);
    });

    test('restok produk yang tidak ada memberi NotFoundFailure', () async {
      expect(
        failureOf(await repository.restock(999, 10)),
        isA<NotFoundFailure>(),
      );
    });

    test('updateProduct tidak bisa mengubah stok diam-diam', () async {
      // Ini yang menjaga ledger tidak bolong: form produk mengirim seluruh
      // entity, tapi kolom stock sengaja diabaikan repository.
      final id = (await repository.addProduct(draft(stock: 10))).getOrElse(
        () => -1,
      );
      final product = (await repository.watchAllProducts().first).single;

      await repository.updateProduct(
        product.copyWith(name: 'Nama baru', stock: 999),
      );

      expect(await stockOf(id), 10);
      expect(await ledgerOf(id), hasLength(1));
      expect(
        (await repository.watchAllProducts().first).single.name,
        'Nama baru',
      );
    });
  });

  group('hapus vs ledger', () {
    // Regresi: setelah FK ditegakkan + stok awal ikut dicatat, produk sempat
    // jadi tidak bisa dihapus sama sekali karena ledger-nya menahan.
    test('produk yang belum pernah terjual tetap bisa dihapus', () async {
      final id = (await repository.addProduct(draft(stock: 10))).getOrElse(
        () => -1,
      );
      await repository.restock(id, 5);
      expect(await ledgerOf(id), hasLength(2));

      expect(failureOf(await repository.deleteProduct(id)), isNull);
      expect(await repository.watchAllProducts().first, isEmpty);
      // ledger-nya ikut hilang, tidak meninggalkan baris menggantung
      expect(await ledgerOf(id), isEmpty);
    });

    test('gagal hapus karena transaksi tidak menghapus ledger', () async {
      final id = (await repository.addProduct(draft(stock: 10))).getOrElse(
        () => -1,
      );
      final transactionId = await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              total: 25000,
              paymentAmount: 25000,
              change: 0,
            ),
          );
      await db.into(db.transactionItems).insert(
        TransactionItemsCompanion.insert(
          transactionId: transactionId,
          productId: id,
          qty: 1,
          priceAtSale: 25000,
        ),
      );

      expect(
        failureOf(await repository.deleteProduct(id)),
        isA<DatabaseFailure>(),
      );
      // transaksi di-rollback: produk DAN ledger-nya tetap utuh
      expect(await repository.watchAllProducts().first, hasLength(1));
      expect(await ledgerOf(id), hasLength(1));
    });
  });

  group('daftar stok menipis', () {
    test('memakai batas per produk, bukan satu angka global', () async {
      // menipis: stok 3 <= batas 5
      await repository.addProduct(draft(name: 'Menipis', stock: 3));
      // aman: stok 3 tapi batasnya 1
      await repository.addProduct(
        draft(name: 'Aman', stock: 3, lowStockThreshold: 1),
      );
      // habis: selalu ikut
      await repository.addProduct(draft(name: 'Habis', stock: 0));
      // aman jauh di atas batas
      await repository.addProduct(draft(name: 'Banyak', stock: 100));

      final lowStock = await repository.watchLowStockProducts().first;

      expect(lowStock.map((p) => p.name), containsAll(['Menipis', 'Habis']));
      expect(lowStock.map((p) => p.name), isNot(contains('Aman')));
      expect(lowStock.map((p) => p.name), isNot(contains('Banyak')));
      // diurutkan stok paling sedikit duluan
      expect(lowStock.first.name, 'Habis');
    });

    test('produk nonaktif tidak ikut daftar belanja', () async {
      await repository.addProduct(
        draft(name: 'Nonaktif', stock: 0, isActive: false),
      );
      expect(await repository.watchLowStockProducts().first, isEmpty);
    });

    test('daftar ter-update sendiri setelah restok', () async {
      final id = (await repository.addProduct(draft(stock: 2))).getOrElse(
        () => -1,
      );

      final emissions = <List<ProductEntity>>[];
      final subscription = repository.watchLowStockProducts().listen(
        emissions.add,
      );
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      expect(emissions.last, hasLength(1));

      await repository.restock(id, 50);
      await pumpEventQueue();
      expect(emissions.last, isEmpty);
    });
  });
}
