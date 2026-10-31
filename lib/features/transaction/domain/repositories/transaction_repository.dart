import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';

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
}
