import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/core/widgets/app_avatar.dart';
import 'package:henshin/features/transaction/presentation/screens/cashier_screen.dart';

/// Chip kategori di Kasir hanya untuk kategori yang punya produk **siap jual**.
/// Fungsi murni, jadi diuji `test()` biasa — bukan lewat widget (ADR-012).
void main() {
  const minuman = CategoryEntity(id: 1, name: 'Minuman');
  const makanan = CategoryEntity(id: 2, name: 'Makanan');

  ProductEntity product({
    required int categoryId,
    int stock = 10,
    bool isActive = true,
  }) {
    return ProductEntity(
      id: categoryId * 100 + stock,
      name: 'Produk $categoryId',
      price: 5000,
      costPrice: 3000,
      stock: stock,
      lowStockThreshold: 2,
      isActive: isActive,
      categoryId: categoryId,
    );
  }

  test('kategori tanpa produk tidak muncul', () {
    final result = categoriesWithSellableProducts(
      [minuman, makanan],
      [product(categoryId: 1)],
    );
    expect(result.map((c) => c.name), ['Minuman']);
  });

  test('kategori yang semua produknya habis tidak muncul', () {
    final result = categoriesWithSellableProducts(
      [minuman],
      [product(categoryId: 1, stock: 0)],
    );
    expect(result, isEmpty);
  });

  test('kategori yang semua produknya nonaktif tidak muncul', () {
    final result = categoriesWithSellableProducts(
      [minuman],
      [product(categoryId: 1, isActive: false)],
    );
    expect(result, isEmpty);
  });

  test('satu produk siap jual sudah cukup untuk memunculkan kategorinya', () {
    final result = categoriesWithSellableProducts(
      [minuman],
      [product(categoryId: 1, stock: 0), product(categoryId: 1, stock: 3)],
    );
    expect(result, [minuman]);
  });

  test('inisial avatar: nama kosong tidak membuat crash', () {
    expect(productInitial('  '), '?');
    expect(productInitial('kopi'), 'K');
  });
}
