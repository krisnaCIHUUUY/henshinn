import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';

class WatchProductByCategory {
  final ProductRepository repository;

  WatchProductByCategory(this.repository);

  Stream<List<ProductEntity>> call(int categoryId) {
    return repository.watchProductsByCategory(categoryId);
  }

}