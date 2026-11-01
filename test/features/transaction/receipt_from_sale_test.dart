import 'dart:io';

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
import 'package:henshin/features/transaction/data/services/pdf_printer_service.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';
import 'package:henshin/features/transaction/domain/entities/receipt.dart';
import 'package:henshin/features/transaction/domain/receipt_formatter.dart';
import 'package:path/path.dart' as p;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProductRepositoryImpl products;
  late SettingsRepositoryImpl settings;
  late TransactionRepositoryImpl sales;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    products = ProductRepositoryImpl(ProductDao(db), CategoryDao(db));
    settings = SettingsRepositoryImpl(SettingsDao(db));
    sales = TransactionRepositoryImpl(TransactionDao(db), settings);
    await db.select(db.categories).get(); // paksa seed
  });

  tearDown(() => db.close());

  Future<ProductEntity> addProduct(String name, int price, int cost) async {
    await products.addProduct(
      NewProduct(
        name: name,
        price: price,
        costPrice: cost,
        stock: 50,
        categoryId: 1,
      ),
    );
    return (await products.watchAllProducts().first).firstWhere(
      (p) => p.name == name,
    );
  }

  Future<int> sell(List<CartItem> items, int payment) async =>
      (await sales.createSale(
        items: items,
        paymentAmount: payment,
      )).getOrElse(() => -1);

  test('struk dibangun dari transaksi tersimpan, lengkap', () async {
    await settings.updateStoreInfo(
      name: 'Toko Henshin',
      address: 'Jl. Merdeka 1',
      receiptMessage: 'Terima kasih',
    );

    final kopi = await addProduct('Kopi', 25000, 15000);
    final teh = await addProduct('Teh', 8000, 3000);
    final id = await sell([
      CartItem(product: kopi, qty: 2),
      CartItem(product: teh, qty: 1),
    ], 100000);

    final receipt = (await sales.buildReceipt(id)).getOrElse(
      () => throw StateError('struk gagal dibangun'),
    );

    expect(receipt.transactionId, id);
    expect(receipt.storeName, 'Toko Henshin');
    expect(receipt.storeAddress, 'Jl. Merdeka 1');
    expect(receipt.footerMessage, 'Terima kasih');
    expect(receipt.lines, hasLength(2));
    expect(receipt.total, 58000);
    expect(receipt.paymentAmount, 100000);
    expect(receipt.change, 42000);
    expect(receipt.itemCount, 3);
    expect(receipt.isVoided, isFalse);
    expect(receipt.isReprint, isFalse);
  });

  test('struk memakai snapshot: harga produk diubah, struk tidak berubah',
      () async {
    final kopi = await addProduct('Kopi', 25000, 15000);
    final id = await sell([CartItem(product: kopi, qty: 1)], 25000);

    await products.updateProduct(
      kopi.copyWith(name: 'Kopi Spesial', price: 40000),
    );

    final receipt = (await sales.buildReceipt(id)).getOrElse(
      () => throw StateError('gagal'),
    );
    expect(receipt.lines.single.name, 'Kopi');
    expect(receipt.lines.single.unitPrice, 25000);
    expect(receipt.total, 25000);
  });

  test('tanpa info toko, struk tetap bisa dibangun tanpa header', () async {
    final kopi = await addProduct('Kopi', 25000, 15000);
    final id = await sell([CartItem(product: kopi, qty: 1)], 25000);

    final receipt = (await sales.buildReceipt(id)).getOrElse(
      () => throw StateError('gagal'),
    );
    expect(receipt.storeName, isEmpty);

    final lines = const ReceiptFormatter().format(receipt);
    expect(lines.first, startsWith('No   : #'));
  });

  test('transaksi tidak ada memberi NotFoundFailure', () async {
    final result = await sales.buildReceipt(999);
    expect(
      result.fold((f) => f, (_) => null),
      isA<NotFoundFailure>(),
    );
  });

  test('isReprint diteruskan ke struk', () async {
    final kopi = await addProduct('Kopi', 25000, 15000);
    final id = await sell([CartItem(product: kopi, qty: 1)], 25000);

    final receipt = (await sales.buildReceipt(id, isReprint: true)).getOrElse(
      () => throw StateError('gagal'),
    );
    expect(receipt.isReprint, isTrue);
    expect(
      const ReceiptFormatter().formatAsText(receipt),
      contains('CETAK ULANG'),
    );
  });

  group('PDF', () {
    test('menghasilkan file PDF yang valid dan tidak kosong', () async {
      final kopi = await addProduct('Kopi', 25000, 15000);
      final id = await sell([CartItem(product: kopi, qty: 2)], 50000);
      final receipt = (await sales.buildReceipt(id)).getOrElse(
        () => throw StateError('gagal'),
      );

      final bytes = await PdfPrinterService().buildPdf(receipt);

      expect(bytes, isNotEmpty);
      // header berkas PDF
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(500));
    });

    test('nama dengan karakter non-Latin1 tidak menggagalkan PDF', () async {
      // Courier hanya Latin-1. Sebelumnya karakter di luar itu bisa membuat
      // PDF gagal/kosong, dan gejalanya muncul sebagai "gagal membagikan".
      final receipt = Receipt(
        transactionId: 1,
        dateTime: DateTime(2026, 10, 31),
        lines: const [
          ReceiptLine(name: 'Kopi 日本 ☕ émigré', qty: 1, unitPrice: 25000),
        ],
        total: 25000,
        paymentAmount: 25000,
        storeName: 'Toko 東京',
      );

      final bytes = await PdfPrinterService().buildPdf(receipt);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('file ditulis ke direktori yang disuntik, bukan systemTemp', () async {
      // Regresi: default-nya dulu `Directory.systemTemp`, yang di Android
      // menunjuk /tmp dan tidak bisa ditulis — share selalu gagal di HP
      // walau tes di desktop lolos.
      final dir = Directory.systemTemp.createTempSync('henshin_pdf_test');
      addTearDown(() => dir.deleteSync(recursive: true));

      final kopi = await addProduct('Kopi', 25000, 15000);
      final id = await sell([CartItem(product: kopi, qty: 1)], 25000);
      final receipt = (await sales.buildReceipt(id)).getOrElse(
        () => throw StateError('gagal'),
      );

      final service = PdfPrinterService(outputDirectory: () async => dir);
      final bytes = await service.buildPdf(receipt);
      final file = File(p.join(dir.path, 'struk-$id.pdf'));
      await file.writeAsBytes(bytes);

      expect(file.existsSync(), isTrue);
      expect(await file.length(), greaterThan(500));
    });

    test('struk panjang tetap jadi satu dokumen', () async {
      final receipt = Receipt(
        transactionId: 1,
        dateTime: DateTime(2026, 10, 31),
        lines: [
          for (var i = 0; i < 40; i++)
            ReceiptLine(name: 'Produk nomor $i', qty: 2, unitPrice: 12500),
        ],
        total: 1000000,
        paymentAmount: 1000000,
        storeName: 'Toko Henshin',
      );

      final bytes = await PdfPrinterService().buildPdf(receipt);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('info toko', () {
    test('tersimpan dan terbaca ulang', () async {
      expect(
        (await settings.getStoreInfo()).getOrElse(
          () => throw StateError('gagal'),
        ).name,
        isEmpty,
      );

      await settings.updateStoreInfo(name: 'Toko Henshin');
      final info = (await settings.getStoreInfo()).getOrElse(
        () => throw StateError('gagal'),
      );
      expect(info.name, 'Toko Henshin');
      expect(info.hasHeader, isTrue);
    });

    test('hanya field yang diisi yang berubah', () async {
      await settings.updateStoreInfo(
        name: 'Toko Henshin',
        address: 'Jl. Merdeka 1',
      );
      await settings.updateStoreInfo(receiptMessage: 'Terima kasih');

      final info = (await settings.getStoreInfo()).getOrElse(
        () => throw StateError('gagal'),
      );
      expect(info.name, 'Toko Henshin');
      expect(info.address, 'Jl. Merdeka 1');
      expect(info.receiptMessage, 'Terima kasih');
    });

    test('nilai di-trim sebelum disimpan', () async {
      await settings.updateStoreInfo(name: '  Toko Henshin  ');
      expect(
        (await settings.getStoreInfo()).getOrElse(
          () => throw StateError('gagal'),
        ).name,
        'Toko Henshin',
      );
    });

    test('watchStoreInfo memancarkan perubahan', () async {
      final emissions = <String>[];
      final subscription = settings.watchStoreInfo().listen(
        (info) => emissions.add(info.name),
      );
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      await settings.updateStoreInfo(name: 'Toko Henshin');
      await pumpEventQueue();

      expect(emissions.last, 'Toko Henshin');
    });
  });
}
