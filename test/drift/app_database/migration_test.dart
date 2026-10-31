// dart format width=80
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('migration from v1 to v2 does not corrupt data', () async {
    // Satu kategori + dua produk + satu transaksi lengkap: cukup untuk
    // membuktikan baris v1 selamat dan kolom baru terisi default.
    final oldCategoriesData = <v1.CategoriesData>[
      const v1.CategoriesData(id: 1, name: 'Minuman'),
    ];
    final expectedNewCategoriesData = <v2.CategoriesData>[
      const v2.CategoriesData(id: 1, name: 'Minuman'),
    ];

    final oldProductsData = <v1.ProductsData>[
      const v1.ProductsData(
        id: 1,
        name: 'Cappuccino',
        price: 25000,
        stock: 45,
        categoryId: 1,
        barcode: '8991234567890',
      ),
      const v1.ProductsData(
        id: 2,
        name: 'Teh Botol',
        price: 8000,
        stock: 3,
        categoryId: 1,
      ),
    ];
    // costPrice -> 0, lowStockThreshold -> 5, isActive -> 1 (true) dari default
    // kolom baru; harga/stok lama tidak boleh berubah.
    final expectedNewProductsData = <v2.ProductsData>[
      const v2.ProductsData(
        id: 1,
        name: 'Cappuccino',
        price: 25000,
        costPrice: 0,
        stock: 45,
        lowStockThreshold: 5,
        isActive: 1,
        categoryId: 1,
        barcode: '8991234567890',
      ),
      const v2.ProductsData(
        id: 2,
        name: 'Teh Botol',
        price: 8000,
        costPrice: 0,
        stock: 3,
        lowStockThreshold: 5,
        isActive: 1,
        categoryId: 1,
      ),
    ];

    const transactionDate = 1762000000; // unix detik, nilai tetap
    final oldTransactionsData = <v1.TransactionsData>[
      const v1.TransactionsData(
        id: 1,
        date: transactionDate,
        total: 33000,
        paymentAmount: 50000,
        change: 17000,
        status: 'completed',
      ),
    ];
    final expectedNewTransactionsData = <v2.TransactionsData>[
      const v2.TransactionsData(
        id: 1,
        date: transactionDate,
        total: 33000,
        paymentAmount: 50000,
        change: 17000,
        status: 'completed',
      ),
    ];

    final oldTransactionItemsData = <v1.TransactionItemsData>[
      const v1.TransactionItemsData(
        id: 1,
        transactionId: 1,
        productId: 1,
        qty: 1,
        priceAtSale: 25000,
      ),
      const v1.TransactionItemsData(
        id: 2,
        transactionId: 1,
        productId: 2,
        qty: 1,
        priceAtSale: 8000,
      ),
    ];
    final expectedNewTransactionItemsData = <v2.TransactionItemsData>[
      const v2.TransactionItemsData(
        id: 1,
        transactionId: 1,
        productId: 1,
        qty: 1,
        priceAtSale: 25000,
      ),
      const v2.TransactionItemsData(
        id: 2,
        transactionId: 1,
        productId: 2,
        qty: 1,
        priceAtSale: 8000,
      ),
    ];

    final oldStockMovementsData = <v1.StockMovementsData>[
      const v1.StockMovementsData(
        id: 1,
        productId: 1,
        type: 'out',
        quantity: -1,
        note: 'penjualan #1',
        createdAt: transactionDate,
      ),
    ];
    final expectedNewStockMovementsData = <v2.StockMovementsData>[
      const v2.StockMovementsData(
        id: 1,
        productId: 1,
        type: 'out',
        quantity: -1,
        note: 'penjualan #1',
        createdAt: transactionDate,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.categories, oldCategoriesData);
        batch.insertAll(oldDb.products, oldProductsData);
        batch.insertAll(oldDb.transactions, oldTransactionsData);
        batch.insertAll(oldDb.transactionItems, oldTransactionItemsData);
        batch.insertAll(oldDb.stockMovements, oldStockMovementsData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewCategoriesData,
          await newDb.select(newDb.categories).get(),
        );
        expect(
          expectedNewProductsData,
          await newDb.select(newDb.products).get(),
        );
        expect(
          expectedNewTransactionsData,
          await newDb.select(newDb.transactions).get(),
        );
        expect(
          expectedNewTransactionItemsData,
          await newDb.select(newDb.transactionItems).get(),
        );
        expect(
          expectedNewStockMovementsData,
          await newDb.select(newDb.stockMovements).get(),
        );
      },
    );
  });
}
