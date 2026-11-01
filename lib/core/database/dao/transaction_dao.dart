import 'package:drift/drift.dart';

import 'package:henshin/core/database/app_database.dart';

part 'transaction_dao.g.dart';

/// Dilempar dari dalam `transaction()` saat stok tidak cukup, supaya seluruh
/// penjualan di-rollback — bukan tersimpan separuh.
class InsufficientStockException implements Exception {
  InsufficientStockException(this.productName, this.available, this.requested);

  final String productName;
  final int available;
  final int requested;

  @override
  String toString() =>
      'Stok $productName tinggal $available, diminta $requested';
}

/// Satu baris keranjang yang siap disimpan. Snapshot nama dan harga diambil
/// dari DB di dalam transaksi, bukan dari UI, supaya tidak bisa dipalsukan
/// atau basi (PRD §2.6).
class SaleLine {
  const SaleLine({required this.productId, required this.qty});

  final int productId;
  final int qty;
}

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

  /// Riwayat + jumlah item per transaksi dalam satu query (join + group by),
  /// supaya list tidak melakukan N query hitung item.
  ///
  /// `since` null berarti semua transaksi. Yang void **ikut** ditampilkan:
  /// riwayat adalah jejak audit, bukan daftar penjualan sah (PRD §2.4).
  Stream<List<(Transaction, int)>> watchHistory({DateTime? since}) {
    final itemCount = transactionItems.qty.sum();
    final query = select(transactions).join([
      leftOuterJoin(
        transactionItems,
        transactionItems.transactionId.equalsExp(transactions.id),
        useColumns: false,
      ),
    ]);
    if (since != null) {
      query.where(transactions.date.isBiggerOrEqualValue(since));
    }
    query
      ..addColumns([itemCount])
      ..groupBy([transactions.id])
      // id desc sebagai pemecah seri: `date` beresolusi detik, jadi dua
      // transaksi di detik yang sama akan tampil dengan urutan acak tanpa ini.
      ..orderBy([
        OrderingTerm.desc(transactions.date),
        OrderingTerm.desc(transactions.id),
      ]);

    return query.watch().map(
      (rows) => rows
          .map((row) => (row.readTable(transactions), row.read(itemCount) ?? 0))
          .toList(),
    );
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

  Future<Transaction?> getTransactionById(int id) {
    return (select(
      transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Detail item dalam satu transaksi
  Future<List<TransactionItem>> getItemsByTransactionId(int transactionId) {
    return (select(
      transactionItems,
    )..where((i) => i.transactionId.equals(transactionId))).get();
  }

  /// Simpan penjualan: header + item + pengurangan stok + ledger, **satu
  /// transaksi Drift**. Ini yang PRD §3.2 sebut tidak boleh dipotong — kalau
  /// ada satu langkah gagal, tidak ada apa pun yang tersimpan.
  ///
  /// Total dihitung ulang di sini dari harga di DB; angka dari UI tidak
  /// dipercaya. Mengembalikan id transaksi.
  Future<int> createSale({
    required List<SaleLine> lines,
    required int paymentAmount,
  }) {
    return transaction(() async {
      var total = 0;
      final snapshots = <TransactionItemsCompanion>[];

      for (final line in lines) {
        final product = await (select(
          products,
        )..where((p) => p.id.equals(line.productId))).getSingleOrNull();

        if (product == null) {
          throw StateError('Produk ${line.productId} tidak ditemukan');
        }
        if (product.stock < line.qty) {
          // Melempar di dalam transaction() membatalkan seluruh penjualan.
          throw InsufficientStockException(
            product.name,
            product.stock,
            line.qty,
          );
        }

        total += product.price * line.qty;
        snapshots.add(
          TransactionItemsCompanion.insert(
            transactionId: 0, // diisi setelah header dibuat
            productId: product.id,
            qty: line.qty,
            productName: Value(product.name),
            priceAtSale: product.price,
            costPriceAtSale: Value(product.costPrice),
          ),
        );
      }

      if (paymentAmount < total) {
        throw StateError('Uang diterima kurang dari total');
      }

      final transactionId = await into(transactions).insert(
        TransactionsCompanion.insert(
          total: total,
          paymentAmount: paymentAmount,
          change: paymentAmount - total,
        ),
      );

      for (var i = 0; i < snapshots.length; i++) {
        await into(transactionItems).insert(
          snapshots[i].copyWith(transactionId: Value(transactionId)),
        );

        final line = lines[i];
        await (update(
          products,
        )..where((p) => p.id.equals(line.productId))).write(
          ProductsCompanion.custom(stock: products.stock - Variable(line.qty)),
        );
        await into(stockMovements).insert(
          StockMovementsCompanion.insert(
            productId: line.productId,
            type: 'out',
            quantity: -line.qty,
            note: Value('Penjualan #$transactionId'),
          ),
        );
      }

      return transactionId;
    });
  }

  /// Void = soft delete (PRD §2.4): status jadi `voided` + alasan, stok item
  /// dikembalikan, dan tiap pengembalian menulis satu baris ledger. Semua
  /// dalam satu transaksi Drift.
  ///
  /// Transaksi yang sudah void ditolak — kalau tidak, stoknya akan kembali
  /// dua kali dan jumlahnya jadi salah.
  Future<void> voidTransaction(int transactionId, String reason) async {
    await transaction(() async {
      final header = await getTransactionById(transactionId);
      if (header == null) {
        throw StateError('Transaksi #$transactionId tidak ditemukan');
      }
      if (header.status == 'voided') {
        throw StateError('Transaksi #$transactionId sudah void');
      }

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
