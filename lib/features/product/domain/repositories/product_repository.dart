import 'package:dartz/dartz.dart';

import '../entities/product.dart';
import '../../../../core/errors/failures.dart';

abstract class ProductRepository {
  /// Stream semua produk, auto-update saat data berubah.
  Stream<List<ProductEntity>> watchAllProducts();

  /// Stream produk berdasarkan kategori tertentu.
  Stream<List<ProductEntity>> watchProductsByCategory(int categoryId);

  /// Stream kategori untuk pilihan di form produk. Ikut di repository ini
  /// karena kategori belum punya CRUD sendiri — baru dipakai baca-saja.
  Stream<List<CategoryEntity>> watchCategories();

  /// Stream produk aktif yang stoknya <= batas per produk sendiri.
  Stream<List<ProductEntity>> watchLowStockProducts();

  Future<Either<Failure, List<ProductEntity>>> searchProducts(String keyword);

  Future<Either<Failure, ProductEntity?>> getProductByBarcode(String barcode);

  Future<Either<Failure, ProductEntity?>> getProductById(int id);

  Future<Either<Failure, int>> addProduct(NewProduct product);

  Future<Either<Failure, void>> updateProduct(ProductEntity product);

  Future<Either<Failure, void>> deleteProduct(int id);

  /// Barang masuk: stok naik + 1 baris `stock_movements`, atomik.
  Future<Either<Failure, void>> restock(int productId, int qty, {String? note});

  /// Koreksi ke hasil hitung fisik; ledger mencatat selisihnya.
  Future<Either<Failure, void>> adjustStock(
    int productId,
    int newStock, {
    String? note,
  });
}
