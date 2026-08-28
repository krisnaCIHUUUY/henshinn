import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';

class WatchAllProducts {
  final ProductRepository repository;

  WatchAllProducts(this.repository);

  Stream<List<ProductEntity>> call() {
    return repository.watchAllProducts();
  }
}