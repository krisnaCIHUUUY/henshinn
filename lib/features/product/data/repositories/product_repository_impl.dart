import 'package:dartz/dartz.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/category_dao.dart';
import 'package:henshin/core/database/dao/product_dao.dart';
import 'package:henshin/features/product/data/model/product_model.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductDao _productDao;
  final CategoryDao _categoryDao;

  ProductRepositoryImpl(this._productDao, this._categoryDao);

  @override
  Stream<List<ProductEntity>> watchAllProducts() {
    return _productDao.watchAllProducts().map(
      (rows) => rows.map(ProductModel.toEntity).toList(),
    );
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    return _categoryDao.watchAllCategories().map(
      (rows) => rows.map(ProductModel.toCategoryEntity).toList(),
    );
  }

  @override
  Stream<List<ProductEntity>> watchProductsByCategory(int categoryId) {
    return _productDao
        .watchProductsByCategory(categoryId)
        .map((rows) => rows.map(ProductModel.toEntity).toList());
  }

  @override
  Stream<List<ProductEntity>> watchFrequentProducts() {
    return _productDao.watchFrequentProducts().map(
      (rows) => rows.map(ProductModel.toEntity).toList(),
    );
  }

  @override
  Stream<List<ProductEntity>> watchLowStockProducts() {
    return _productDao.watchLowStockProducts().map(
      (rows) => rows.map(ProductModel.toEntity).toList(),
    );
  }

  @override
  Future<Either<Failure, int>> findOrCreateCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('Nama kategori tidak boleh kosong'));
    }

    try {
      final existing = await _categoryDao.findCategoryByName(trimmed);
      if (existing != null) return Right(existing.id);
      return Right(
        await _categoryDao.addCategory(
          CategoriesCompanion.insert(name: trimmed),
        ),
      );
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyimpan kategori: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> searchProducts(
    String keyword,
  ) async {
    try {
      final rows = await _productDao.searchProducts(keyword);
      final products = rows.map(ProductModel.toEntity).toList();
      return Right(products);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mencari produk: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity?>> getProductByBarcode(
    String barcode,
  ) async {
    try {
      // Dinormalkan sama seperti saat disimpan (`_blankToNull` ikut `trim`).
      // Tanpa ini jalur tulis dan jalur baca tidak sepakat soal apa kuncinya:
      // barcode disimpan sudah dipangkas, tapi kode dari scanner dicari apa
      // adanya, dan `equals` di DAO itu pencocokan persis. Beberapa simbologi
      // 1D (Code 39) juga mengembalikan rawValue dengan karakter penutup.
      final normalized = barcode.trim();
      if (normalized.isEmpty) return const Right(null);

      final row = await _productDao.getProductByBarcode(normalized);
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
    final invalid = _validate(
      name: product.name,
      price: product.price,
      costPrice: product.costPrice,
      stock: product.stock,
      lowStockThreshold: product.lowStockThreshold,
    );
    if (invalid != null) return Left(invalid);

    try {
      final companion = ProductModel.toInsertCompanion(_normalizeNew(product));
      final id = await _productDao.addProduct(companion);
      return Right(id);
    } catch (e) {
      return Left(_mapWriteError(e, 'menambah'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(ProductEntity product) async {
    final invalid = _validate(
      name: product.name,
      price: product.price,
      costPrice: product.costPrice,
      stock: product.stock,
      lowStockThreshold: product.lowStockThreshold,
    );
    if (invalid != null) return Left(invalid);

    try {
      final companion = ProductModel.toCompanion(_normalize(product));
      // Stok sengaja tidak ikut: hanya restock/adjustStock yang boleh
      // mengubahnya, supaya tiap perubahan stok punya baris ledger.
      final success = await _productDao.updateProductDetails(
        product.id,
        companion,
      );
      if (!success) {
        return const Left(NotFoundFailure('Produk tidak ditemukan'));
      }
      return const Right(null);
    } catch (e) {
      return Left(_mapWriteError(e, 'memperbarui'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int id) async {
    try {
      // Diambil lebih dulu supaya pesan gagalnya bisa menyebut nama produknya
      // dan tahu produk itu sudah nonaktif atau belum.
      final product = await _productDao.getProductById(id);
      if (product == null) {
        return const Left(NotFoundFailure('Produk tidak ditemukan'));
      }

      try {
        await _productDao.deleteProduct(id);
      } catch (e) {
        // Satu-satunya FK yang masih menunjuk produk saat delete dijalankan
        // adalah `transaction_items`: ledger stoknya ikut terhapus di
        // transaksi yang sama (`ProductDao.deleteProduct`). Jadi FK gagal
        // berarti produknya pernah terjual, bukan sebab lain.
        //
        // Dulu blok ini melabeli SETIAP exception sebagai masalah transaksi,
        // jadi error apa pun muncul sebagai "sudah dipakai di transaksi".
        if (!e.toString().contains('FOREIGN KEY constraint failed')) rethrow;
        return Left(DatabaseFailure(_soldMessage(product)));
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menghapus produk: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> restock(
    int productId,
    int qty, {
    String? note,
  }) async {
    if (qty <= 0) {
      return const Left(ValidationFailure('Jumlah restok harus lebih dari 0'));
    }
    try {
      if (await _productDao.getProductById(productId) == null) {
        return const Left(NotFoundFailure('Produk tidak ditemukan'));
      }
      await _productDao.restock(productId, qty, note: _blankToNull(note));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mencatat restok: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> adjustStock(
    int productId,
    int newStock, {
    String? note,
  }) async {
    if (newStock < 0) {
      return const Left(ValidationFailure('Stok tidak boleh negatif'));
    }
    try {
      if (await _productDao.getProductById(productId) == null) {
        return const Left(NotFoundFailure('Produk tidak ditemukan'));
      }
      await _productDao.adjustStock(
        productId,
        newStock,
        note: _blankToNull(note),
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mencatat koreksi stok: $e'));
    }
  }

  // ===== internal =====

  /// Produk yang pernah terjual tidak bisa dihapus: baris
  /// `transaction_items`-nya adalah riwayat penjualan, dan void tidak
  /// membebaskannya — barisnya tetap ada supaya laporan lama tidak berubah
  /// (PRD §2.6). Saran "nonaktifkan" hanya ditampilkan kalau produknya memang
  /// masih aktif; menyarankannya pada produk yang sudah nonaktif membuat
  /// pesannya terbaca seolah aplikasi mengira produk itu masih aktif
  /// (dilaporkan pemilik 2026-11-08).
  String _soldMessage(Product product) {
    final advice = product.isActive
        ? 'Nonaktifkan saja produknya supaya tidak muncul di kasir.'
        : 'Produk ini sudah nonaktif dan tidak muncul di kasir.';
    return '${product.name} sudah pernah terjual, jadi tidak bisa dihapus — '
        'riwayat penjualannya akan ikut hilang. $advice';
  }

  /// Barcode kosong disimpan sebagai NULL, bukan string kosong — kalau tidak,
  /// produk kedua tanpa barcode akan bentrok dengan index unik.
  String? _blankToNull(String? barcode) {
    final trimmed = barcode?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  NewProduct _normalizeNew(NewProduct p) => NewProduct(
    name: p.name.trim(),
    price: p.price,
    costPrice: p.costPrice,
    stock: p.stock,
    lowStockThreshold: p.lowStockThreshold,
    isActive: p.isActive,
    categoryId: p.categoryId,
    barcode: _blankToNull(p.barcode),
    imagePath: p.imagePath,
  );

  ProductEntity _normalize(ProductEntity p) =>
      p.copyWith(name: p.name.trim(), barcode: _blankToNull(p.barcode));

  ValidationFailure? _validate({
    required String name,
    required int price,
    required int costPrice,
    required int stock,
    required int lowStockThreshold,
  }) {
    if (name.trim().isEmpty) {
      return const ValidationFailure('Nama produk tidak boleh kosong');
    }
    if (price < 0) {
      return const ValidationFailure('Harga jual tidak boleh negatif');
    }
    if (costPrice < 0) {
      return const ValidationFailure('Harga modal tidak boleh negatif');
    }
    if (stock < 0) {
      return const ValidationFailure('Stok tidak boleh negatif');
    }
    if (lowStockThreshold < 0) {
      return const ValidationFailure('Batas stok menipis tidak boleh negatif');
    }
    return null;
  }

  /// Index unik barcode ditegakkan di DB; di sini exception SQLite-nya
  /// diterjemahkan supaya user tidak melihat pesan mentah.
  Failure _mapWriteError(Object error, String action) {
    final message = error.toString();
    if (message.contains('products_barcode_unique') ||
        message.contains('UNIQUE constraint failed: products.barcode')) {
      return const ValidationFailure('Barcode sudah dipakai produk lain');
    }
    return DatabaseFailure('Gagal $action produk: $error');
  }
}
