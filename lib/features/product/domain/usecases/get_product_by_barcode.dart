import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';

class GetProductByBarcode {
  final ProductRepository repository;

  GetProductByBarcode(this.repository);

  Future<Either<Failure, ProductEntity?>> call(String barcode) {
    return repository.getProductByBarcode(barcode);
  }
}
