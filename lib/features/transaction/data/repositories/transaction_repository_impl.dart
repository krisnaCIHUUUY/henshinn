import 'package:dartz/dartz.dart';
import 'package:henshin/core/database/dao/transaction_dao.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/setting/domain/entities/store_info.dart';
import 'package:henshin/features/setting/domain/repositories/settings_repository.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';
import 'package:henshin/features/transaction/domain/entities/receipt.dart';
import 'package:henshin/features/transaction/domain/entities/transaction_summary.dart';
import 'package:henshin/features/transaction/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDao _transactionDao;
  final SettingsRepository _settingsRepository;

  TransactionRepositoryImpl(this._transactionDao, this._settingsRepository);

  @override
  Future<Either<Failure, Receipt>> buildReceipt(
    int transactionId, {
    bool isReprint = false,
  }) async {
    try {
      final header = await _transactionDao.getTransactionById(transactionId);
      if (header == null) {
        return const Left(NotFoundFailure('Transaksi tidak ditemukan'));
      }

      final items = await _transactionDao.getItemsByTransactionId(
        transactionId,
      );

      // Info toko opsional: kalau gagal dibaca, struk tetap tercetak tanpa
      // header daripada gagal sama sekali.
      final store = (await _settingsRepository.getStoreInfo()).getOrElse(
        () => const StoreInfo(),
      );

      return Right(
        Receipt(
          transactionId: header.id,
          dateTime: header.date,
          lines: items
              .map(
                (item) => ReceiptLine(
                  name: item.productName,
                  qty: item.qty,
                  unitPrice: item.priceAtSale,
                ),
              )
              .toList(),
          total: header.total,
          paymentAmount: header.paymentAmount,
          storeName: store.name,
          storeAddress: store.address,
          footerMessage: store.receiptMessage,
          isVoided: header.status == 'voided',
          voidReason: header.voidReason,
          isReprint: isReprint,
        ),
      );
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyusun struk: $e'));
    }
  }

  @override
  Stream<List<TransactionSummary>> watchHistory({DateTime? since}) {
    return _transactionDao.watchHistory(since: since).map(
      (rows) => rows
          .map(
            (row) => TransactionSummary(
              id: row.$1.id,
              dateTime: row.$1.date,
              total: row.$1.total,
              itemCount: row.$2,
              isVoided: row.$1.status == 'voided',
            ),
          )
          .toList(),
    );
  }

  @override
  Future<Either<Failure, Unit>> voidTransaction(
    int transactionId,
    String reason,
  ) async {
    if (reason.trim().isEmpty) {
      return const Left(ValidationFailure('Alasan void tidak boleh kosong'));
    }

    try {
      await _transactionDao.voidTransaction(transactionId, reason.trim());
      return const Right(unit);
    } on StateError catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Gagal void transaksi: $e'));
    }
  }

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
