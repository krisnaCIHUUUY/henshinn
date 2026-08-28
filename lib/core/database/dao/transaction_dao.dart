import 'package:drift/drift.dart';

import 'package:henshin/core/database/app_database.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(
  tables: [Transactions, TransactionItems, Products, StockMovements],
)
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  // Riwayat transaksi, terbaru duluan
  Stream<List<Transaction>> watchTransactionHistory() {
    return (select(
      transactions,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
  }

  // Transaksi dalam rentang tanggal (untuk laporan harian)
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..where((t) => t.status.equals('completed')))
        .get();
  }

  // Detail item dalam satu transaksi
  Future<List<TransactionItem>> getItemsByTransactionId(int transactionId) {
    return (select(
      transactionItems,
    )..where((i) => i.transactionId.equals(transactionId))).get();
  }

  // Buat transaksi baru + item-nya + kurangi stok, dalam satu operasi atomic
  Future<int> createTransactionWithItems({
    required TransactionsCompanion transactionData,
    required List<TransactionItemsCompanion> items,
  }) async {
    return transaction(() async {
      final transactionId = await into(transactions).insert(transactionData);

      for (final item in items) {
        await into(transactionItems)
            .insert(item.copyWith(transactionId: Value(transactionId)));

        final productId = item.productId.value;
        final qty = item.qty.value;

        // kurangi stok
        await (update(products)..where((p) => p.id.equals(productId))).write(
          ProductsCompanion.custom(stock: products.stock - Variable(qty)),
        );

        // catat pergerakan stok
        await into(stockMovements).insert(
          StockMovementsCompanion.insert(
            productId: productId,
            type: 'out',
            quantity: -qty,
            note: const Value('Penjualan'),
          ),
        );
      }

      return transactionId;
    });
  }

  // Void transaksi: ubah status + kembalikan stok
  Future<void> voidTransaction(int transactionId, String reason) async {
    await transaction(() async {
      await (update(
        transactions,
      )..where((t) => t.id.equals(transactionId))).write(
        TransactionsCompanion(
          status: const Value('voided'),
          voidReason: Value(reason),
        ),
      );

      final items = await getItemsByTransactionId(transactionId);
      for (final item in items) {
        await (update(
          products,
        )..where((p) => p.id.equals(item.productId))).write(
          ProductsCompanion.custom(stock: products.stock + Variable(item.qty)),
        );

        await into(stockMovements).insert(
          StockMovementsCompanion.insert(
            productId: item.productId,
            type: 'in',
            quantity: item.qty,
            note: const Value('Void transaksi'),
          ),
        );
      }
    });
  }
}
