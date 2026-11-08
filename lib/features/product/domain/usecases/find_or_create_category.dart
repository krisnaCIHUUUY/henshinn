import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';

class FindOrCreateCategory {
  final ProductRepository repository;

  FindOrCreateCategory(this.repository);

  Future<Either<Failure, int>> call(String name) {
    return repository.findOrCreateCategory(name);
  }
}
