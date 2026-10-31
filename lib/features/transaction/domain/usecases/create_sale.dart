import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';
import 'package:henshin/features/transaction/domain/repositories/transaction_repository.dart';

class CreateSale {
  final TransactionRepository repository;

  CreateSale(this.repository);

  Future<Either<Failure, int>> call({
    required List<CartItem> items,
    required int paymentAmount,
  }) {
    return repository.createSale(items: items, paymentAmount: paymentAmount);
  }
}
