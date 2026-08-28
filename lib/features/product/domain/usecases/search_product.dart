import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';

class SearchProduct {
  final ProductRepository repository;

  SearchProduct(this.repository);

  Future<Either<Failure, List<ProductEntity>>> call(String keyword) {
    return repository.searchProducts(keyword);
  }
}
