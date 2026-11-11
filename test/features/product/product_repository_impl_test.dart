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

  /// Satu penjualan produk [productId]; mengembalikan id transaksinya.
  Future<int> sell(int productId) async {
    final transactionId = await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        total: 25000,
        paymentAmount: 25000,
        change: 0,
      ),
    );
    await db.into(db.transactionItems).insert(
      TransactionItemsCompanion.insert(
        transactionId: transactionId,
        productId: productId,
        qty: 1,
        priceAtSale: 25000,
      ),
    );
    return transactionId;
  }

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

    // Jalur simpan memangkas barcode (`_blankToNull`), jadi jalur cari wajib
    // memangkas dengan cara yang sama — kalau tidak, keduanya tidak sepakat
    // soal apa kuncinya dan produk yang terdaftar jadi "tidak ditemukan".
    test('kode dari scanner yang berspasi tetap menemukan produknya', () async {
      await repository.addProduct(draft(barcode: '8991234567890'));

      final result = await repository.getProductByBarcode(
        ' 8991234567890\n',
      );
      expect(result.getOrElse(() => null)?.name, 'Cappuccino');
    });

    test('barcode disimpan berspasi pun tetap bisa dicari tanpa spasi',
        () async {
      await repository.addProduct(draft(barcode: '  8991234567890  '));

      final result = await repository.getProductByBarcode('8991234567890');
      expect(result.getOrElse(() => null)?.name, 'Cappuccino');
    });

    test('kode kosong atau hanya spasi mengembalikan null, bukan produk '
        'tanpa barcode', () async {
      await repository.addProduct(draft(name: 'Tanpa barcode', barcode: ''));

      for (final kode in ['', '   ']) {
        final result = await repository.getProductByBarcode(kode);
        expect(failureOf(result), isNull);
        expect(result.getOrElse(() => null), isNull, reason: 'kode "$kode"');
      }
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
      expect(failure!.message, contains('pernah terjual'));
      // Masih aktif, jadi sarannya memang relevan.
      expect(failure.message, contains('Nonaktifkan'));
      expect(await repository.watchAllProducts().first, hasLength(1));
    });

    // Dilaporkan pemilik 2026-11-08: pesan lama menyuruh menonaktifkan produk
    // yang sudah nonaktif, jadi terbaca seolah aplikasi mengira produk itu
    // masih aktif.
    test('produk nonaktif yang pernah terjual ditolak tanpa menyuruh '
        'menonaktifkannya lagi', () async {
      final id = (await repository.addProduct(
        draft(name: 'Es Teh', isActive: false),
      )).getOrElse(() => -1);
      await sell(id);

      final failure = failureOf(await repository.deleteProduct(id));

      expect(failure!.message, contains('Es Teh'));
      expect(failure.message, contains('pernah terjual'));
      expect(failure.message, contains('sudah nonaktif'));
      expect(failure.message, isNot(contains('Nonaktifkan saja')));
    });

    // Void menandai transaksinya 'voided' tapi barisnya tetap ada (PRD §2.6),
    // jadi produknya tetap terkunci. Mengejutkan tanpa konteks ini.
    test('void transaksi tidak membuat produknya bisa dihapus', () async {
      final id = (await repository.addProduct(draft())).getOrElse(() => -1);
      final transactionId = await sell(id);
      await db.customStatement(
        "UPDATE transactions SET status = 'voided' WHERE id = $transactionId",
      );

      final failure = failureOf(await repository.deleteProduct(id));

      expect(failure, isA<DatabaseFailure>());
      expect(failure!.message, contains('pernah terjual'));
    });

    test('produk nonaktif yang belum pernah terjual tetap bisa dihapus',
        () async {
      final id = (await repository.addProduct(
        draft(isActive: false),
      )).getOrElse(() => -1);

      expect((await repository.deleteProduct(id)).isRight(), isTrue);
      expect(await repository.watchAllProducts().first, isEmpty);
    });
  });

  group('cari-atau-buat kategori', () {
    test('nama baru membuat satu kategori', () async {
      final id = (await repository.findOrCreateCategory('Minuman'))
          .getOrElse(() => -1);

      final rows = await db.select(db.categories).get();
      expect(rows.map((c) => c.name), ['Umum', 'Minuman']);
      expect(rows.last.id, id);
    });

    test('nama yang sama persis memakai kategori lama', () async {
      final first = (await repository.findOrCreateCategory('Minuman'))
          .getOrElse(() => -1);
      final second = (await repository.findOrCreateCategory('Minuman'))
          .getOrElse(() => -2);

      expect(second, first);
      expect(await db.select(db.categories).get(), hasLength(2));
    });

    // Keputusan pemilik: beda kapitalisasi bukan kategori baru, dan bukan
    // error — produknya masuk ke kategori yang sudah ada (ADR-038).
    test('beda huruf besar kecil memakai kategori lama', () async {
      final first = (await repository.findOrCreateCategory('Minuman'))
          .getOrElse(() => -1);
      final second = (await repository.findOrCreateCategory('mInUmAn'))
          .getOrElse(() => -2);

      expect(second, first);
      expect(await db.select(db.categories).get(), hasLength(2));
    });

    test('spasi di ujung tidak membuat kategori kembar', () async {
      final first = (await repository.findOrCreateCategory('Minuman'))
          .getOrElse(() => -1);
      final second = (await repository.findOrCreateCategory('  Minuman  '))
          .getOrElse(() => -2);

      expect(second, first);
      expect(await db.select(db.categories).get(), hasLength(2));
    });

    test('nama kosong ditolak dan tidak menulis apa pun', () async {
      final failure = failureOf(await repository.findOrCreateCategory('   '));

      expect(failure, isA<ValidationFailure>());
      expect(await db.select(db.categories).get(), hasLength(1));
    });

    test('produk bisa langsung dipakai dengan kategori yang baru dibuat',
        () async {
      final categoryId = (await repository.findOrCreateCategory('Minuman'))
          .getOrElse(() => -1);

      final result = await repository.addProduct(
        NewProduct(name: 'Es Teh', price: 5000, categoryId: categoryId),
      );

      expect(result.isRight(), isTrue);
      final products = await repository.watchAllProducts().first;
      expect(products.single.categoryId, categoryId);
    });
  });

  group('produk sering dibeli (terlaris 30 hari)', () {
    /// Penjualan dengan kendali penuh: qty, umur transaksi, dan statusnya.
    Future<void> sellAt(
      int productId, {
      int qty = 1,
      int daysAgo = 0,
      String status = 'completed',
    }) async {
      final transactionId = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          total: 25000,
          paymentAmount: 25000,
          change: 0,
          date: Value(DateTime.now().subtract(Duration(days: daysAgo))),
          status: Value(status),
        ),
      );
      await db.into(db.transactionItems).insert(
        TransactionItemsCompanion.insert(
          transactionId: transactionId,
          productId: productId,
          qty: qty,
          priceAtSale: 25000,
        ),
      );
    }

    Future<int> add(String name, {int stock = 10, bool isActive = true}) async {
      final result = await repository.addProduct(
        draft(name: name, stock: stock, isActive: isActive),
      );
      return result.getOrElse(() => -1);
    }

    test('urut dari yang paling banyak terjual', () async {
      final kopi = await add('Kopi');
      final teh = await add('Teh');
      await sellAt(kopi, qty: 2);
      await sellAt(teh, qty: 9);

      final result = await repository.watchFrequentProducts().first;
      expect(result.map((p) => p.name), ['Teh', 'Kopi']);
    });

    test('penjualan lebih dari 30 hari lalu tidak dihitung', () async {
      final kopi = await add('Kopi');
      await sellAt(kopi, qty: 5, daysAgo: 40);

      expect(await repository.watchFrequentProducts().first, isEmpty);
    });

    test('transaksi void tidak dihitung', () async {
      final kopi = await add('Kopi');
      await sellAt(kopi, qty: 5, status: 'voided');

      expect(await repository.watchFrequentProducts().first, isEmpty);
    });

    test('produk nonaktif tidak muncul walau terlaris', () async {
      final kopi = await add('Kopi', isActive: false);
      await sellAt(kopi, qty: 9);

      expect(await repository.watchFrequentProducts().first, isEmpty);
    });

    test('produk yang stoknya habis tidak muncul', () async {
      final kopi = await add('Kopi', stock: 0);
      await sellAt(kopi, qty: 9);

      expect(await repository.watchFrequentProducts().first, isEmpty);
    });
  });
}
