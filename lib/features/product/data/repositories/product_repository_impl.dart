import 'package:dartz/dartz.dart';
import 'package:henshin/core/database/dao/product_dao.dart';
import 'package:henshin/features/product/data/model/product_model.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductDao _productDao;

  ProductRepositoryImpl(this._productDao);

  @override
  Stream<List<ProductEntity>> watchAllProducts() {
    return _productDao.watchAllProducts().map(
      (rows) => rows.map(ProductModel.toEntity).toList(),
    );
  }

  @override
  Stream<List<ProductEntity>> watchProductsByCategory(int categoryId) {
    return _productDao
        .watchProductsByCategory(categoryId)
        .map((rows) => rows.map(ProductModel.toEntity).toList());
  }

  @override
  Stream<List<ProductEntity>> watchLowStockProducts(int threshold) {
    return _productDao
        .watchLowStockProducts(threshold)
        .map((rows) => rows.map(ProductModel.toEntity).toList());
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> searchProducts(String keyword) async {
    try {
      final rows = await _productDao.searchProducts(keyword);
      final products = rows.map(ProductModel.toEntity).toList();
      return Right(products);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mencari produk: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity?>> getProductByBarcode(String barcode) async {
    try {
      final row = await _productDao.getProductByBarcode(barcode);
      if (row == null) return const Right(null);
      return Right(ProductModel.toEntity(row));
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil produk: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity?>> getProductById(int id) async {
    try {
      final row = await _productDao.getProductById(id);
      if (row == null) return const Right(null);
      return Right(ProductModel.toEntity(row));
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil produk: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> addProduct(NewProduct product) async {
    try {
      // Validasi ringan di level repository (opsional — validasi utama tetap di usecase)
      if (product.name.trim().isEmpty) {
        return const Left(ValidationFailure('Nama produk tidak boleh kosong'));
      }
      if (product.price < 0) {
        return const Left(ValidationFailure('Harga tidak boleh negatif'));
      }

      final companion = ProductModel.toInsertCompanion(product);
      final id = await _productDao.addProduct(companion);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menambah produk: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(ProductEntity product) async {
    try {
      final companion = ProductModel.toCompanion(product);
      final success = await _productDao.updateProduct(companion);
      if (!success) {
        return const Left(NotFoundFailure('Produk tidak ditemukan'));
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Gagal memperbarui produk: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int id) async {
    try {
      final rowsAffected = await _productDao.deleteProduct(id);
      if (rowsAffected == 0) {
        return const Left(NotFoundFailure('Produk tidak ditemukan'));
      }
      return const Right(null);
    } catch (e) {
      // Kemungkinan besar: FK constraint karena produk masih dipakai di transaction_items
      return Left(DatabaseFailure('Gagal menghapus produk: $e'));
    }
  }
}
