import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/category_dao.dart';
import 'package:henshin/core/database/dao/product_dao.dart';
import 'package:henshin/core/database/dao/report_dao.dart';
import 'package:henshin/core/database/dao/settings_dao.dart';
import 'package:henshin/core/database/dao/transaction_dao.dart';
import 'package:henshin/features/product/data/repositories/product_repository_impl.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/report/data/repositories/report_repository_impl.dart';
import 'package:henshin/features/report/domain/entities/sales_report.dart';
import 'package:henshin/features/setting/data/repositories/settings_repository_impl.dart';
import 'package:henshin/features/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // "Sekarang" dikunci di tengah hari supaya tes tidak pecah kalau dijalankan
  // dekat tengah malam.
  final now = DateTime(2026, 11, 1, 12);

  late AppDatabase db;
  late ProductRepositoryImpl products;
  late TransactionRepositoryImpl sales;
  late ReportRepositoryImpl reports;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    products = ProductRepositoryImpl(ProductDao(db), CategoryDao(db));
    sales = TransactionRepositoryImpl(
      TransactionDao(db),
      SettingsRepositoryImpl(SettingsDao(db)),
    );
    reports = ReportRepositoryImpl(ReportDao(db), now: () => now);
    await db.select(db.categories).get(); // paksa seed
  });

  tearDown(() => db.close());

  Future<ProductEntity> addProduct(
    String name, {
    int price = 25000,
    int cost = 15000,
  }) async {
    await products.addProduct(
      NewProduct(
        name: name,
        price: price,
        costPrice: cost,
        stock: 500,
        categoryId: 1,
      ),
    );
    return (await products.watchAllProducts().first).firstWhere(
      (p) => p.name == name,
    );
  }

  /// Menjual lalu menggeser tanggal transaksinya, karena `createSale` selalu
  /// memakai waktu sekarang.
  Future<int> sellOn(DateTime when, List<CartItem> items) async {
    final total = items.fold(
      0,
      (sum, i) => sum + i.product.price * i.qty,
    );
    final id = (await sales.createSale(
      items: items,
      paymentAmount: total,
    )).getOrElse(() => -1);
    expect(id, greaterThan(0));

    await db.customStatement('UPDATE transactions SET date = ? WHERE id = ?', [
      when.millisecondsSinceEpoch ~/ 1000,
      id,
    ]);
    return id;
  }

  Future<SalesReport> report(ReportPeriod period) async =>
      (await reports.getReport(period)).getOrElse(
        () => throw StateError('laporan gagal'),
      );

  group('rentang periode', () {
    test('hari ini = satu hari kalender, bukan 24 jam ke belakang', () {
      final (start, end) = ReportPeriod.hariIni.rangeFrom(now);
      expect(start, DateTime(2026, 11, 1));
      expect(end.isBefore(DateTime(2026, 11, 2)), isTrue);
      expect(end.isAfter(DateTime(2026, 11, 1, 23, 59, 59)), isTrue);
    });

    test('7 hari = hari ini + 6 hari sebelumnya', () {
      final (start, _) = ReportPeriod.tujuhHari.rangeFrom(now);
      expect(start, DateTime(2026, 10, 26)); // 1 Nov − 6 hari
    });

    test('30 hari = hari ini + 29 hari sebelumnya', () {
      final (start, _) = ReportPeriod.tigaPuluhHari.rangeFrom(now);
      expect(start, DateTime(2026, 10, 3));
    });
  });

  group('angka laporan', () {
    test('omzet, laba, jumlah transaksi, dan item sesuai hitungan manual',
        () async {
      final kopi = await addProduct('Kopi', price: 25000, cost: 15000);
      final teh = await addProduct('Teh', price: 8000, cost: 3000);

      // Hari ini: 2 kopi + 3 teh, lalu 1 kopi lagi.
      await sellOn(now, [
        CartItem(product: kopi, qty: 2),
        CartItem(product: teh, qty: 3),
      ]);
      await sellOn(now, [CartItem(product: kopi, qty: 1)]);

      final r = await report(ReportPeriod.hariIni);
      expect(r.revenue, 2 * 25000 + 3 * 8000 + 25000); // 99.000
      expect(r.grossProfit, 2 * 10000 + 3 * 5000 + 10000); // 45.000
      expect(r.transactionCount, 2);
      expect(r.itemCount, 6);
      expect(r.averageSale, 99000 ~/ 2);
    });

    test('periode kosong memberi nol, bukan error', () async {
      final r = await report(ReportPeriod.hariIni);
      expect(r.revenue, 0);
      expect(r.grossProfit, 0);
      expect(r.transactionCount, 0);
      expect(r.itemCount, 0);
      expect(r.averageSale, 0);
      expect(r.bestSellers, isEmpty);
    });

    test('transaksi void tidak dihitung di angka mana pun', () async {
      final kopi = await addProduct('Kopi');
      final dipakai = await sellOn(now, [CartItem(product: kopi, qty: 2)]);
      final dibatalkan = await sellOn(now, [CartItem(product: kopi, qty: 5)]);

      await sales.voidTransaction(dibatalkan, 'salah input');

      final r = await report(ReportPeriod.hariIni);
      expect(r.transactionCount, 1);
      expect(r.revenue, 2 * 25000);
      expect(r.grossProfit, 2 * 10000);
      expect(r.itemCount, 2);
      expect(r.bestSellers.single.qtySold, 2);
      expect(dipakai, isNot(dibatalkan));
    });

    test('transaksi di luar periode tidak ikut', () async {
      final kopi = await addProduct('Kopi');
      await sellOn(now, [CartItem(product: kopi, qty: 1)]);
      await sellOn(now.subtract(const Duration(days: 10)), [
        CartItem(product: kopi, qty: 4),
      ]);

      expect((await report(ReportPeriod.hariIni)).itemCount, 1);
      expect((await report(ReportPeriod.tujuhHari)).itemCount, 1);
      expect((await report(ReportPeriod.tigaPuluhHari)).itemCount, 5);
    });

    test('laba memakai harga snapshot, bukan harga produk sekarang', () async {
      final kopi = await addProduct('Kopi', price: 25000, cost: 15000);
      await sellOn(now, [CartItem(product: kopi, qty: 2)]);

      await products.updateProduct(
        kopi.copyWith(price: 90000, costPrice: 80000),
      );

      final r = await report(ReportPeriod.hariIni);
      expect(r.revenue, 50000);
      expect(r.grossProfit, 20000); // bukan 2 * 10.000 dari harga baru
    });
  });

  group('produk terlaris', () {
    test('diurutkan dari qty terbanyak', () async {
      final kopi = await addProduct('Kopi');
      final teh = await addProduct('Teh');
      final susu = await addProduct('Susu');

      await sellOn(now, [
        CartItem(product: kopi, qty: 3),
        CartItem(product: teh, qty: 9),
        CartItem(product: susu, qty: 5),
      ]);

      final r = await report(ReportPeriod.hariIni);
      expect(r.bestSellers.map((b) => b.name), ['Teh', 'Susu', 'Kopi']);
      expect(r.bestSellers.first.qtySold, 9);
    });

    test('qty digabung dari beberapa transaksi', () async {
      final kopi = await addProduct('Kopi');
      await sellOn(now, [CartItem(product: kopi, qty: 2)]);
      await sellOn(now, [CartItem(product: kopi, qty: 3)]);

      final r = await report(ReportPeriod.hariIni);
      expect(r.bestSellers, hasLength(1));
      expect(r.bestSellers.single.qtySold, 5);
    });

    test('produk yang sudah dihapus tetap muncul dengan nama snapshot',
        () async {
      final kopi = await addProduct('Kopi');
      await sellOn(now, [CartItem(product: kopi, qty: 2)]);
      await products.deleteProduct(kopi.id);

      final r = await report(ReportPeriod.hariIni);
      expect(r.bestSellers.single.name, 'Kopi');
    });
  });

  group('omzet per hari', () {
    test('hari tanpa penjualan tetap ada dengan nilai 0', () async {
      final kopi = await addProduct('Kopi');
      await sellOn(now, [CartItem(product: kopi, qty: 1)]);
      await sellOn(now.subtract(const Duration(days: 2)), [
        CartItem(product: kopi, qty: 2),
      ]);

      final r = await report(ReportPeriod.tujuhHari);
      expect(r.daily, hasLength(7));
      expect(r.daily.first.date, DateTime(2026, 10, 26));
      expect(r.daily.last.date, DateTime(2026, 11, 1));
      expect(r.daily.last.revenue, 25000);
      expect(
        r.daily.firstWhere((d) => d.date == DateTime(2026, 10, 30)).revenue,
        50000,
      );
      expect(
        r.daily.firstWhere((d) => d.date == DateTime(2026, 10, 31)).revenue,
        0,
      );
    });

    test('penjualan jam 1 pagi masuk hari itu, bukan hari sebelumnya',
        () async {
      // Regresi zona waktu: drift menyimpan unix epoch UTC, jadi mengelompokkan
      // dengan strftime akan memindahkan transaksi dini hari WIB ke hari lain.
      final kopi = await addProduct('Kopi');
      await sellOn(DateTime(2026, 11, 1, 1, 15), [
        CartItem(product: kopi, qty: 1),
      ]);

      final r = await report(ReportPeriod.hariIni);
      expect(r.daily.single.date, DateTime(2026, 11, 1));
      expect(r.daily.single.revenue, 25000);
      expect(r.revenue, 25000);
    });
  });
}
