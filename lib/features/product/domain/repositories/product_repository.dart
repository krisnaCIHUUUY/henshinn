import 'package:dartz/dartz.dart';

import '../entities/product.dart';
import '../../../../core/errors/failures.dart';

abstract class ProductRepository {
  /// Stream semua produk, auto-update saat data berubah.
  Stream<List<ProductEntity>> watchAllProducts();

  /// Stream produk berdasarkan kategori tertentu.
  Stream<List<ProductEntity>> watchProductsByCategory(int categoryId);

  /// Stream produk dengan stok di bawah/sama dengan threshold.
  Stream<List<ProductEntity>> watchLowStockProducts(int threshold);

  Future<Either<Failure, List<ProductEntity>>> searchProducts(String keyword);

  Future<Either<Failure, ProductEntity?>> getProductByBarcode(String barcode);

  Future<Either<Failure, ProductEntity?>> getProductById(int id);

  Future<Either<Failure, int>> addProduct(NewProduct product);

  Future<Either<Failure, void>> updateProduct(ProductEntity product);

  Future<Either<Failure, void>> deleteProduct(int id);
}
