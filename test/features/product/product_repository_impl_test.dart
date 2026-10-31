import 'package:drift/drift.dart' hide isNull, isNotNull;
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

  // Kategori 'Umum' hasil seed langkah 2 — FK categoryId butuh baris nyata.
  const categoryId = 1;

  NewProduct draft({
    String name = 'Cappuccino',
    int price = 25000,
    int costPrice = 15000,
    int stock = 10,
    int lowStockThreshold = 5,
    bool isActive = true,
    String? barcode,
  }) => NewProduct(
    name: name,
    price: price,
    costPrice: costPrice,
    stock: stock,
    lowStockThreshold: lowStockThreshold,
    isActive: isActive,
    categoryId: categoryId,
    barcode: barcode,
  );

  Failure? failureOf(dynamic either) =>
      either.fold((Failure f) => f, (_) => null);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = ProductRepositoryImpl(ProductDao(db), CategoryDao(db));
    // Paksa beforeOpen jalan supaya kategori default ada sebelum tes.
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  group('list reaktif', () {
    test('tambah, ubah, hapus terlihat di watchAllProducts', () async {
      final emissions = <List<ProductEntity>>[];
      final subscription = repository.watchAllProducts().listen(
        emissions.add,
      );
      addTearDown(subscription.cancel);

      // emisi awal: kosong
      await pumpEventQueue();
      expect(emissions.last, isEmpty);

      // tambah
      final added = await repository.addProduct(draft());
      final id = added.getOrElse(() => -1);
      await pumpEventQueue();
      expect(emissions.last.map((p) => p.name), ['Cappuccino']);
      expect(emissions.last.single.price, 25000);

      // ubah
      final current = emissions.last.single;
      await repository.updateProduct(
        current.copyWith(name: 'Cappuccino Besar', price: 30000),
      );
      await pumpEventQueue();
      expect(emissions.last.single.name, 'Cappuccino Besar');
      expect(emissions.last.single.price, 30000);

      // hapus
      await repository.deleteProduct(id);
      await pumpEventQueue();
      expect(emissions.last, isEmpty);

      // tiap operasi memancarkan ulang, bukan sekali di akhir
      expect(emissions.length, greaterThanOrEqualTo(4));
    });

    test('watchCategories memancarkan kategori hasil seed', () async {
      final categories = await repository.watchCategories().first;
      expect(categories.map((c) => c.name), [kDefaultCategoryName]);
    });

    test('kolom baru langkah 2 ikut tersimpan dan terbaca', () async {
      await repository.addProduct(
        draft(costPrice: 7000, lowStockThreshold: 3, isActive: false),
      );

      final product = (await repository.watchAllProducts().first).single;
      expect(product.costPrice, 7000);
      expect(product.lowStockThreshold, 3);
      expect(product.isActive, isFalse);
      expect(product.margin, 25000 - 7000);
    });
  });

  group('validasi harga & stok', () {
    test('nama kosong ditolak', () async {
      final result = await repository.addProduct(draft(name: '   '));
      expect(failureOf(result), isA<ValidationFailure>());
      expect(await repository.watchAllProducts().first, isEmpty);
    });

    test('harga, modal, stok, threshold negatif ditolak', () async {
      final cases = <String, NewProduct>{
        'harga': draft(price: -1),
        'modal': draft(costPrice: -1),
        'stok': draft(stock: -1),
        'threshold': draft(lowStockThreshold: -1),
      };

      for (final entry in cases.entries) {
        expect(
          failureOf(await repository.addProduct(entry.value)),
          isA<ValidationFailure>(),
          reason: '${entry.key} negatif seharusnya ditolak',
        );
      }
      expect(await repository.watchAllProducts().first, isEmpty);
    });

    test('update dengan harga negatif ditolak, data lama tidak berubah',
        () async {
      await repository.addProduct(draft());
      final original = (await repository.watchAllProducts().first).single;

      final result = await repository.updateProduct(
        original.copyWith(price: -5000),
      );
      expect(failureOf(result), isA<ValidationFailure>());
      expect(
        (await repository.watchAllProducts().first).single.price,
        original.price,
      );
    });

    test('harga 0 boleh — produk gratis/bonus bukan error', () async {
      final result = await repository.addProduct(draft(price: 0, costPrice: 0));
      expect(failureOf(result), isNull);
    });
  });

  group('barcode nullable unik', () {
    test('barcode kembar ditolak dengan pesan yang bisa dibaca', () async {
      await repository.addProduct(draft(barcode: '8991234567890'));

      final result = await repository.addProduct(
        draft(name: 'Produk lain', barcode: '8991234567890'),
      );

      final failure = failureOf(result);
      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, 'Barcode sudah dipakai produk lain');
      expect(await repository.watchAllProducts().first, hasLength(1));
    });

    test('banyak produk tanpa barcode boleh (NULL tidak kena unik)', () async {
      expect(failureOf(await repository.addProduct(draft(name: 'A'))), isNull);
      expect(failureOf(await repository.addProduct(draft(name: 'B'))), isNull);
      expect(
        failureOf(await repository.addProduct(draft(name: 'C', barcode: ''))),
        isNull,
      );

      final products = await repository.watchAllProducts().first;
      expect(products, hasLength(3));
      // barcode kosong disimpan NULL, bukan string kosong
      expect(products.map((p) => p.barcode), everyElement(isNull));
    });

    test('update ke barcode milik produk lain ditolak', () async {
      await repository.addProduct(draft(name: 'A', barcode: '111'));
      await repository.addProduct(draft(name: 'B', barcode: '222'));

      final b = (await repository.watchAllProducts().first).firstWhere(
        (p) => p.name == 'B',
      );
      final result = await repository.updateProduct(
        b.copyWith(barcode: '111'),
      );

      expect(failureOf(result), isA<ValidationFailure>());
    });

    test('nama dan barcode di-trim sebelum disimpan', () async {
      await repository.addProduct(
        draft(name: '  Teh Botol  ', barcode: '  333  '),
      );

      final product = (await repository.watchAllProducts().first).single;
      expect(product.name, 'Teh Botol');
      expect(product.barcode, '333');
    });
  });

  group('cari produk via barcode (dasar alur scan)', () {
    // Scanner tidak bisa diuji otomatis (butuh kamera fisik), tapi pencarian
    // yang dipakainya bisa — ini yang menentukan "dikenal" vs "fallback".
    test('barcode terdaftar mengembalikan produknya', () async {
      await repository.addProduct(draft(barcode: '8991234567890'));

      final result = await repository.getProductByBarcode('8991234567890');
      expect(result.getOrElse(() => null)?.name, 'Cappuccino');
    });

    test('barcode asing mengembalikan null, bukan error', () async {
      await repository.addProduct(draft(barcode: '111'));

      final result = await repository.getProductByBarcode('tidak-ada');
      expect(failureOf(result), isNull);
      expect(result.getOrElse(() => null), isNull);
    });

    test('produk nonaktif tetap ditemukan — penyaringan ada di pemanggil',
        () async {
      await repository.addProduct(
        draft(name: 'Nonaktif', barcode: '222', isActive: false),
      );

      final product = (await repository.getProductByBarcode(
        '222',
      )).getOrElse(() => null);
      expect(product, isNotNull);
      expect(product!.isActive, isFalse);
    });
  });

  group('hapus', () {
    test('produk yang tidak ada memberi NotFoundFailure', () async {
      expect(
        failureOf(await repository.deleteProduct(999)),
        isA<NotFoundFailure>(),
      );
    });

    test('produk yang dipakai transaksi tidak bisa dihapus', () async {
      final id = (await repository.addProduct(draft())).getOrElse(() => -1);

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

      final failure = failureOf(await repository.deleteProduct(id));
      expect(failure, isA<DatabaseFailure>());
      expect(failure!.message, contains('Nonaktifkan'));
      expect(await repository.watchAllProducts().first, hasLength(1));
    });
  });
}
