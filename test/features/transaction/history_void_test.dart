import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/category_dao.dart';
import 'package:henshin/core/database/dao/product_dao.dart';
import 'package:henshin/core/database/dao/settings_dao.dart';
import 'package:henshin/core/database/dao/transaction_dao.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/product/data/repositories/product_repository_impl.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/setting/data/repositories/settings_repository_impl.dart';
import 'package:henshin/features/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProductRepositoryImpl products;
  late TransactionRepositoryImpl sales;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    products = ProductRepositoryImpl(ProductDao(db), CategoryDao(db));
    sales = TransactionRepositoryImpl(
      TransactionDao(db),
      SettingsRepositoryImpl(SettingsDao(db)),
    );
    await db.select(db.categories).get(); // paksa seed
  });

  tearDown(() => db.close());

  Future<ProductEntity> addProduct(String name, {int stock = 50}) async {
    await products.addProduct(
      NewProduct(
        name: name,
        price: 25000,
        costPrice: 15000,
        stock: stock,
        categoryId: 1,
      ),
    );
    return (await products.watchAllProducts().first).firstWhere(
      (p) => p.name == name,
    );
  }

  Future<int> sell(ProductEntity product, int qty) async =>
      (await sales.createSale(
        items: [CartItem(product: product, qty: qty)],
        paymentAmount: 25000 * qty,
      )).getOrElse(() => -1);

  Future<int> stockOf(int id) async =>
      (await products.watchAllProducts().first)
          .firstWhere((p) => p.id == id)
          .stock;

  group('riwayat', () {
    test('terbaru duluan, dengan jumlah item per transaksi', () async {
      final kopi = await addProduct('Kopi');
      final teh = await addProduct('Teh');

      await sales.createSale(
        items: [CartItem(product: kopi, qty: 2), CartItem(product: teh, qty: 3)],
        paymentAmount: 200000,
      );
      final kedua = await sell(kopi, 1);

      final history = await sales.watchHistory().first;
      expect(history, hasLength(2));
      expect(history.first.id, kedua); // terbaru duluan
      expect(history.last.itemCount, 5); // 2 + 3, bukan 2 baris
      expect(history.last.total, 25000 * 5);
      expect(history.first.isVoided, isFalse);
    });

    test('filter since menyaring transaksi lama', () async {
      final kopi = await addProduct('Kopi');
      final id = await sell(kopi, 1);

      // Geser tanggalnya ke 10 hari lalu, lewat DB langsung karena createSale
      // selalu memakai waktu sekarang.
      await db
          .customStatement('UPDATE transactions SET date = ? WHERE id = ?', [
            DateTime.now()
                    .subtract(const Duration(days: 10))
                    .millisecondsSinceEpoch ~/
                1000,
            id,
          ]);

      final sejakSeminggu = await sales
          .watchHistory(
            since: DateTime.now().subtract(const Duration(days: 7)),
          )
          .first;
      expect(sejakSeminggu, isEmpty);

      final semua = await sales.watchHistory().first;
      expect(semua, hasLength(1));
    });

    test('transaksi void tetap muncul di riwayat', () async {
      final kopi = await addProduct('Kopi');
      final id = await sell(kopi, 1);
      await sales.voidTransaction(id, 'salah input');

      final history = await sales.watchHistory().first;
      expect(history.single.isVoided, isTrue);
    });
  });

  group('void', () {
    test('status berubah, stok kembali, dan ledger bertambah', () async {
      final kopi = await addProduct('Kopi', stock: 50);
      final id = await sell(kopi, 4);
      expect(await stockOf(kopi.id), 46);

      final ledgerSebelum = await db.select(db.stockMovements).get();
      final result = await sales.voidTransaction(id, '  barang dikembalikan  ');
      expect(result.isRight(), isTrue);

      expect(await stockOf(kopi.id), 50);

      final receipt = (await sales.buildReceipt(id)).getOrElse(
        () => throw StateError('gagal'),
      );
      expect(receipt.isVoided, isTrue);
      expect(receipt.voidReason, 'barang dikembalikan'); // di-trim

      final ledgerSesudah = await db.select(db.stockMovements).get();
      expect(ledgerSesudah.length, ledgerSebelum.length + 1);
      expect(ledgerSesudah.last.quantity, 4);
      expect(ledgerSesudah.last.type, 'in');
    });

    test('baris transaksi tidak pernah dihapus', () async {
      final kopi = await addProduct('Kopi');
      final id = await sell(kopi, 1);
      await sales.voidTransaction(id, 'salah input');

      expect(await db.select(db.transactions).get(), hasLength(1));
      expect(await db.select(db.transactionItems).get(), hasLength(1));
    });

    test('alasan kosong ditolak dan tidak mengubah apa pun', () async {
      final kopi = await addProduct('Kopi');
      final id = await sell(kopi, 2);

      final result = await sales.voidTransaction(id, '   ');
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
      expect(await stockOf(kopi.id), 48); // stok tidak dikembalikan
    });

    test('void dua kali ditolak: stok tidak boleh kembali dobel', () async {
      final kopi = await addProduct('Kopi', stock: 50);
      final id = await sell(kopi, 5);

      expect((await sales.voidTransaction(id, 'pertama')).isRight(), isTrue);
      expect(await stockOf(kopi.id), 50);

      final kedua = await sales.voidTransaction(id, 'kedua');
      expect(kedua.fold((f) => f, (_) => null), isA<ValidationFailure>());
      expect(await stockOf(kopi.id), 50); // bukan 55
    });

    test('transaksi tidak ada ditolak', () async {
      final result = await sales.voidTransaction(999, 'apa saja');
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });
  });
}
