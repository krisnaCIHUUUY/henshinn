import 'package:drift/drift.dart';
import 'package:henshin/core/database/app_database.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products, Categories])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  // Tambahkan method ini di ProductDao yang sudah dibuat sebelumnya

  Future<Product?> getProductById(int id) {
    return (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  // Ambil semua produk, reactive (auto-update saat data berubah)
  Stream<List<Product>> watchAllProducts() => select(products).watch();

  // Ambil produk berdasarkan kategori
  Stream<List<Product>> watchProductsByCategory(int categoryId) =>
      (select(products)..where((p) => p.categoryId.equals(categoryId))).watch();

  // Cari produk berdasarkan nama atau barcode
  Future<List<Product>> searchProducts(String keyword) {
    final query = select(products)
      ..where((p) => p.name.like('%$keyword%') | p.barcode.like('%$keyword%'));
    return query.get();
  }

  // Ambil satu produk by barcode (untuk scan langsung di kasir)
  Future<Product?> getProductByBarcode(String barcode) {
    return (select(
      products,
    )..where((p) => p.barcode.equals(barcode))).getSingleOrNull();
  }

  // Produk dengan stok menipis (misal <= threshold)
  Stream<List<Product>> watchLowStockProducts(int threshold) {
    return (select(
      products,
    )..where((p) => p.stock.isSmallerOrEqualValue(threshold))).watch();
  }

  Future<int> addProduct(ProductsCompanion product) =>
      into(products).insert(product);

  Future<bool> updateProduct(ProductsCompanion product) =>
      update(products).replace(product);

  Future<int> deleteProduct(int id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();

  // Kurangi stok (dipanggil saat transaksi)
  Future<void> decrementStock(int productId, int qty) async {
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion.custom(stock: products.stock - Variable(qty)),
    );
  }

  // Tambah stok kembali (dipanggil saat void transaksi)
  Future<void> incrementStock(int productId, int qty) async {
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion.custom(stock: products.stock + Variable(qty)),
    );
  }
}
