import 'package:drift/drift.dart';
import 'package:henshin/core/database/app_database.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products, Categories, StockMovements])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

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

  /// Produk yang perlu direstok. Batasnya per produk (`lowStockThreshold`),
  /// bukan satu angka global — dua kolom dibandingkan langsung di SQL.
  Stream<List<Product>> watchLowStockProducts() {
    return (select(products)
          ..where((p) => p.stock.isSmallerOrEqual(p.lowStockThreshold))
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.stock)]))
        .watch();
  }

  /// Insert produk + baris ledger untuk stok awal, dalam satu transaksi.
  /// Stok awal pun perubahan stok, jadi tetap tercatat (PRD §2.6).
  Future<int> addProduct(ProductsCompanion product) {
    return transaction(() async {
      final id = await into(products).insert(product);

      final initialStock = product.stock.present ? product.stock.value : 0;
      if (initialStock != 0) {
        await into(stockMovements).insert(
          StockMovementsCompanion.insert(
            productId: id,
            type: 'in',
            quantity: initialStock,
            note: const Value('Stok awal'),
          ),
        );
      }

      return id;
    });
  }

  /// Sengaja tidak menyentuh kolom `stock`: satu-satunya jalan mengubah stok
  /// adalah [restock] / [adjustStock], supaya ledger tidak pernah bolong.
  Future<bool> updateProductDetails(int id, ProductsCompanion details) async {
    final rows = await (update(products)..where((p) => p.id.equals(id))).write(
      details.copyWith(id: const Value.absent(), stock: const Value.absent()),
    );
    return rows > 0;
  }

  /// Ledger stok hanya milik produk ini, jadi ikut terhapus. FK dari
  /// `transaction_items` tetap menghalangi produk yang sudah pernah terjual,
  /// dan karena satu transaksi, penghapusan ledger ikut dibatalkan kalau gagal.
  Future<int> deleteProduct(int id) {
    return transaction(() async {
      await (delete(stockMovements)..where((m) => m.productId.equals(id))).go();
      return (delete(products)..where((p) => p.id.equals(id))).go();
    });
  }

  /// Barang masuk. Menambah stok + menulis 1 baris ledger, atomik.
  Future<void> restock(int productId, int qty, {String? note}) {
    return transaction(() async {
      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion.custom(stock: products.stock + Variable(qty)),
      );
      await into(stockMovements).insert(
        StockMovementsCompanion.insert(
          productId: productId,
          type: 'in',
          quantity: qty,
          note: Value(note),
        ),
      );
    });
  }

  /// Koreksi stok ke angka hasil hitung fisik. Ledger mencatat selisihnya,
  /// bukan angka akhirnya, supaya penjumlahan ledger tetap cocok dengan stok.
  Future<void> adjustStock(int productId, int newStock, {String? note}) {
    return transaction(() async {
      final current = await getProductById(productId);
      if (current == null) return;

      final delta = newStock - current.stock;
      if (delta == 0) return;

      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(stock: Value(newStock)),
      );
      await into(stockMovements).insert(
        StockMovementsCompanion.insert(
          productId: productId,
          type: 'adjustment',
          quantity: delta,
          note: Value(note),
        ),
      );
    });
  }

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
