import 'package:drift/drift.dart';

import 'package:henshin/core/database/app_database.dart';

part 'report_dao.g.dart';

@DriftAccessor(tables: [Transactions, TransactionItems, Products])
class ReportDao extends DatabaseAccessor<AppDatabase> with _$ReportDaoMixin {
  ReportDao(super.db);

  // Total penjualan dalam rentang tanggal
  Future<int> getTotalSales(DateTime start, DateTime end) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.total.sum()])
      ..where(transactions.date.isBetweenValues(start, end))
      ..where(transactions.status.equals('completed'));

    final result = await query.getSingle();
    return result.read(transactions.total.sum()) ?? 0;
  }

  // Jumlah transaksi dalam rentang tanggal
  Future<int> getTransactionCount(DateTime start, DateTime end) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.id.count()])
      ..where(transactions.date.isBetweenValues(start, end))
      ..where(transactions.status.equals('completed'));

    final result = await query.getSingle();
    return result.read(transactions.id.count()) ?? 0;
  }

  // Produk terlaris (top N berdasarkan qty terjual)
  Future<List<TypedResult>> getBestSellers({
    required DateTime start,
    required DateTime end,
    int limit = 10,
  }) {
    final qtySum = transactionItems.qty.sum();

    final query = selectOnly(transactionItems)
      ..addColumns([transactionItems.productId, qtySum])
      ..join([
        innerJoin(
          transactions,
          transactions.id.equalsExp(transactionItems.transactionId),
        ),
      ])
      ..where(transactions.date.isBetweenValues(start, end))
      ..where(transactions.status.equals('completed'))
      ..groupBy([transactionItems.productId])
      ..orderBy([OrderingTerm.desc(qtySum)])
      ..limit(limit);

    return query.get();
  }
}
