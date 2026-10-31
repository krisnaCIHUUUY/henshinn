import 'package:dartz/dartz.dart';
import 'package:henshin/core/database/dao/transaction_dao.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';
import 'package:henshin/features/transaction/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDao _transactionDao;

  TransactionRepositoryImpl(this._transactionDao);

  @override
  Future<Either<Failure, int>> createSale({
    required List<CartItem> items,
    required int paymentAmount,
  }) async {
    if (items.isEmpty) {
      return const Left(ValidationFailure('Keranjang masih kosong'));
    }
    if (items.any((item) => item.qty <= 0)) {
      return const Left(ValidationFailure('Jumlah item harus lebih dari 0'));
    }

    try {
      final id = await _transactionDao.createSale(
        lines: items
            .map((item) => SaleLine(productId: item.product.id, qty: item.qty))
            .toList(),
        paymentAmount: paymentAmount,
      );
      return Right(id);
    } on InsufficientStockException catch (e) {
      return Left(
        ValidationFailure(
          'Stok ${e.productName} tinggal ${e.available}, '
          'tidak cukup untuk ${e.requested}',
        ),
      );
    } on StateError catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyimpan transaksi: $e'));
    }
  }
}
