import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';
import 'package:henshin/features/transaction/domain/entities/receipt.dart';

abstract class TransactionRepository {
  /// Simpan penjualan secara atomik: header + item (dengan snapshot nama,
  /// harga jual, harga modal) + pengurangan stok + ledger stok, dalam satu
  /// transaksi DB. Mengembalikan id transaksi.
  ///
  /// Total dihitung ulang dari harga di DB, bukan dari angka yang dikirim UI.
  Future<Either<Failure, int>> createSale({
    required List<CartItem> items,
    required int paymentAmount,
  });

  /// Menyusun struk dari transaksi yang sudah tersimpan. Angkanya dari
  /// snapshot `transaction_items`, bukan dari produk saat ini, jadi cetak
  /// ulang struk lama selalu sama (PRD §2.6, US-3.4).
  Future<Either<Failure, Receipt>> buildReceipt(
    int transactionId, {
    bool isReprint = false,
  });
}
