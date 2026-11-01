import 'package:drift/drift.dart';

import 'package:henshin/core/database/app_database.dart';

part 'report_dao.g.dart';

@DriftAccessor(tables: [Transactions, TransactionItems, Products])
class ReportDao extends DatabaseAccessor<AppDatabase> with _$ReportDaoMixin {
  ReportDao(super.db);

  /// Laba kotor + jumlah item terjual, dihitung dari **snapshot** di
  /// `transaction_items` (`priceAtSale - costPriceAtSale`), bukan dari harga
  /// produk yang berlaku sekarang — laporan lama tidak boleh berubah saat
  /// harga diganti (PRD §2.6).
  Future<(int grossProfit, int itemCount)> getProfitAndItemCount(
    DateTime start,
    DateTime end,
  ) async {
    final profitSum =
        ((transactionItems.priceAtSale - transactionItems.costPriceAtSale) *
                transactionItems.qty)
            .sum();
    final qtySum = transactionItems.qty.sum();

    final query = selectOnly(transactionItems)
      ..addColumns([profitSum, qtySum])
      ..join([
        innerJoin(
          transactions,
          transactions.id.equalsExp(transactionItems.transactionId),
          useColumns: false,
        ),
      ])
      ..where(transactions.date.isBetweenValues(start, end))
      ..where(transactions.status.equals('completed'));

    final row = await query.getSingle();
    return (row.read(profitSum) ?? 0, row.read(qtySum) ?? 0);
  }

  /// Produk terlaris (top N berdasarkan qty terjual), memakai nama snapshot
  /// supaya produk yang sudah dihapus tetap muncul di laporan lama.
  ///
  /// `groupBy` di `productId`, bukan di nama: produk yang pernah di-rename
  /// tetap satu baris. SQLite lalu memilih salah satu nama snapshot dari grup
  /// itu — cukup, karena yang dipakai pemilik untuk restok adalah produknya.
  Future<List<(String name, int qtySold)>> getBestSellers({
    required DateTime start,
    required DateTime end,
    int limit = 5,
  }) async {
    final qtySum = transactionItems.qty.sum();

    final query = selectOnly(transactionItems)
      ..addColumns([transactionItems.productName, qtySum])
      ..join([
        innerJoin(
          transactions,
          transactions.id.equalsExp(transactionItems.transactionId),
          useColumns: false,
        ),
      ])
      ..where(transactions.date.isBetweenValues(start, end))
      ..where(transactions.status.equals('completed'))
      ..groupBy([transactionItems.productId])
      ..orderBy([OrderingTerm.desc(qtySum)])
      ..limit(limit);

    final rows = await query.get();
    return [
      for (final row in rows)
        (
          row.read(transactionItems.productName) ?? '',
          row.read(qtySum) ?? 0,
        ),
    ];
  }

  /// Header transaksi lunas dalam rentang, untuk omzet, jumlah transaksi, dan
  /// pengelompokan per hari.
  ///
  /// Pengelompokan per hari dilakukan di Dart, **bukan** dengan fungsi tanggal
  /// SQLite: drift menyimpan waktu sebagai unix epoch UTC, jadi `strftime`
  /// akan memotong hari di jam 07:00 WIB, bukan tengah malam.
  Future<List<Transaction>> getCompletedTransactions(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..where((t) => t.status.equals('completed')))
        .get();
  }
}
