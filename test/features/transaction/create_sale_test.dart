import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/category_dao.dart';
import 'package:henshin/core/database/dao/product_dao.dart';
import 'package:henshin/core/database/dao/transaction_dao.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/product/data/repositories/product_repository_impl.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';
import 'package:path/path.dart' as p;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProductRepositoryImpl products;
  late TransactionRepositoryImpl sales;

  Failure? failureOf(dynamic either) =>
      either.fold((Failure f) => f, (_) => null);

  Future<ProductEntity> addProduct({
    required String name,
    required int price,
    required int costPrice,
    required int stock,
  }) async {
    await products.addProduct(
      NewProduct(
        name: name,
        price: price,
        costPrice: costPrice,
        stock: stock,
        categoryId: 1,
      ),
    );
    return (await products.watchAllProducts().first).firstWhere(
      (product) => product.name == name,
    );
  }

  void wire(AppDatabase database) {
    db = database;
    products = ProductRepositoryImpl(ProductDao(db), CategoryDao(db));
    sales = TransactionRepositoryImpl(TransactionDao(db));
  }

  setUp(() async {
    wire(AppDatabase(NativeDatabase.memory()));
    await db.select(db.categories).get(); // paksa seed kategori default
  });

  // Tes terakhir menutup DB-nya sendiri sebelum menghapus folder temp.
  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  group('transaksi 3 item', () {
    test('total, kembalian, stok, snapshot dan ledger semuanya benar',
        () async {
      final kopi = await addProduct(
        name: 'Kopi',
        price: 25000,
        costPrice: 15000,
        stock: 10,
      );
      final teh = await addProduct(
        name: 'Teh',
        price: 8000,
        costPrice: 3000,
        stock: 20,
      );
      final kue = await addProduct(
        name: 'Kue',
        price: 12000,
        costPrice: 7000,
        stock: 5,
      );

      // 2 kopi + 1 teh + 3 kue = 50000 + 8000 + 36000 = 94000
      final result = await sales.createSale(
        items: [
          CartItem(product: kopi, qty: 2),
          CartItem(product: teh, qty: 1),
          CartItem(product: kue, qty: 3),
        ],
        paymentAmount: 100000,
      );

      final id = result.getOrElse(() => -1);
      expect(id, greaterThan(0));

      final header = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(header.total, 94000);
      expect(header.paymentAmount, 100000);
      expect(header.change, 6000);
      expect(header.status, 'completed');

      final items = await (db.select(
        db.transactionItems,
      )..where((i) => i.transactionId.equals(id))).get();
      expect(items, hasLength(3));

      // snapshot nama + harga jual + harga modal (PRD §2.6)
      final kopiItem = items.firstWhere((i) => i.productId == kopi.id);
      expect(kopiItem.productName, 'Kopi');
      expect(kopiItem.priceAtSale, 25000);
      expect(kopiItem.costPriceAtSale, 15000);
      expect(kopiItem.qty, 2);

      // stok turun sesuai qty
      final after = await products.watchAllProducts().first;
      expect(after.firstWhere((x) => x.id == kopi.id).stock, 8);
      expect(after.firstWhere((x) => x.id == teh.id).stock, 19);
      expect(after.firstWhere((x) => x.id == kue.id).stock, 2);

      // satu baris ledger 'out' per item
      final ledger = await (db.select(
        db.stockMovements,
      )..where((m) => m.type.equals('out'))).get();
      expect(ledger, hasLength(3));
      expect(ledger.map((m) => m.quantity), containsAll([-2, -1, -3]));
      expect(ledger.every((m) => m.note == 'Penjualan #$id'), isTrue);
    });

    test('snapshot tidak berubah walau harga produk diubah setelahnya',
        () async {
      final kopi = await addProduct(
        name: 'Kopi',
        price: 25000,
        costPrice: 15000,
        stock: 10,
      );
      final id = (await sales.createSale(
        items: [CartItem(product: kopi, qty: 1)],
        paymentAmount: 25000,
      )).getOrElse(() => -1);

      await products.updateProduct(
        kopi.copyWith(price: 40000, costPrice: 30000, name: 'Kopi Spesial'),
      );

      final item = await (db.select(
        db.transactionItems,
      )..where((i) => i.transactionId.equals(id))).getSingle();
      expect(item.productName, 'Kopi');
      expect(item.priceAtSale, 25000);
      expect(item.costPriceAtSale, 15000);
    });

    test('total dihitung dari harga DB, bukan dari angka yang dikirim UI',
        () async {
      final kopi = await addProduct(
        name: 'Kopi',
        price: 25000,
        costPrice: 15000,
        stock: 10,
      );

      // UI mengirim entity basi dengan harga 1 rupiah
      final stale = kopi.copyWith(price: 1);
      final id = (await sales.createSale(
        items: [CartItem(product: stale, qty: 2)],
        paymentAmount: 50000,
      )).getOrElse(() => -1);

      final header = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(header.total, 50000, reason: 'harga DB yang dipakai, bukan 1');
      expect(header.change, 0);
    });
  });

  group('keatoman — tidak boleh tersimpan separuh', () {
    test('stok kurang membatalkan seluruh transaksi', () async {
      final kopi = await addProduct(
        name: 'Kopi',
        price: 25000,
        costPrice: 15000,
        stock: 10,
      );
      final kue = await addProduct(
        name: 'Kue',
        price: 12000,
        costPrice: 7000,
        stock: 1, // tidak cukup untuk 3
      );

      final failure = failureOf(
        await sales.createSale(
          items: [
            CartItem(product: kopi, qty: 2),
            CartItem(product: kue, qty: 3),
          ],
          paymentAmount: 100000,
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, contains('Stok Kue tinggal 1'));

      // tidak ada apa pun yang tersimpan — ini inti keatoman
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await db.select(db.transactionItems).get(), isEmpty);
      expect(
        await (db.select(db.stockMovements)..where((m) => m.type.equals('out')))
            .get(),
        isEmpty,
      );

      // stok kopi TIDAK turun walau item pertama sudah diproses
      final after = await products.watchAllProducts().first;
      expect(after.firstWhere((x) => x.id == kopi.id).stock, 10);
      expect(after.firstWhere((x) => x.id == kue.id).stock, 1);
    });

    test('uang kurang dari total ditolak tanpa menyimpan apa pun', () async {
      final kopi = await addProduct(
        name: 'Kopi',
        price: 25000,
        costPrice: 15000,
        stock: 10,
      );

      final failure = failureOf(
        await sales.createSale(
          items: [CartItem(product: kopi, qty: 2)],
          paymentAmount: 10000,
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(
        (await products.watchAllProducts().first).single.stock,
        10,
      );
    });

    test('keranjang kosong ditolak', () async {
      final failure = failureOf(
        await sales.createSale(items: [], paymentAmount: 10000),
      );
      expect(failure, isA<ValidationFailure>());
      expect(await db.select(db.transactions).get(), isEmpty);
    });

    test('menjual tepat sebanyak stok boleh, stok jadi 0', () async {
      final kopi = await addProduct(
        name: 'Kopi',
        price: 25000,
        costPrice: 15000,
        stock: 3,
      );

      expect(
        failureOf(
          await sales.createSale(
            items: [CartItem(product: kopi, qty: 3)],
            paymentAmount: 75000,
          ),
        ),
        isNull,
      );
      expect((await products.watchAllProducts().first).single.stock, 0);
    });
  });

  test('data tetap ada setelah DB ditutup dan dibuka lagi', () async {
    // Pakai file, bukan memory: inilah "reload app" yang rencana minta.
    final dir = Directory.systemTemp.createTempSync('henshin_sale_test');
    final file = File(p.join(dir.path, 'henshin.sqlite'));

    await db.close(); // buang DB in-memory dari setUp
    wire(AppDatabase(NativeDatabase(file)));
    await db.select(db.categories).get();

    final kopi = await addProduct(
      name: 'Kopi',
      price: 25000,
      costPrice: 15000,
      stock: 10,
    );
    final id = (await sales.createSale(
      items: [CartItem(product: kopi, qty: 2)],
      paymentAmount: 50000,
    )).getOrElse(() => -1);
    await db.close();

    // dibuka ulang dari file yang sama
    wire(AppDatabase(NativeDatabase(file)));
    final header = await (db.select(
      db.transactions,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(header.total, 50000);
    expect(
      await (db.select(db.transactionItems)
            ..where((i) => i.transactionId.equals(id)))
          .get(),
      hasLength(1),
    );
    expect((await products.watchAllProducts().first).single.stock, 8);

    // File harus ditutup sebelum foldernya dihapus — di Windows file yang
    // masih terbuka tidak bisa dihapus.
    await db.close();
    dir.deleteSync(recursive: true);
  });
}
