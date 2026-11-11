import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';

/// Daftar "Sering dibeli" di kasir: produk terlaris 30 hari terakhir.
class WatchFrequentProducts {
  final ProductRepository repository;

  WatchFrequentProducts(this.repository);

  Stream<List<ProductEntity>> call() => repository.watchFrequentProducts();
}
