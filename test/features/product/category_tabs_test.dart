import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/presentation/screens/product_list_screen.dart';

/// Tab kategori punya satu aturan yang mudah dilanggar perubahan berikutnya:
/// kategori tanpa produk aktif tidak boleh muncul (ADR-038).
void main() {
  const umum = CategoryEntity(id: 1, name: 'Umum');
  const minuman = CategoryEntity(id: 2, name: 'Minuman');
  const gudang = CategoryEntity(id: 3, name: 'Gudang');

  ProductEntity product({
    required int categoryId,
    bool isActive = true,
    int id = 1,
  }) => ProductEntity(
    id: id,
    name: 'Produk $id',
    price: 5000,
    costPrice: 3000,
    stock: 1,
    lowStockThreshold: 5,
    isActive: isActive,
    categoryId: categoryId,
  );

  test('kategori tanpa produk tidak ikut jadi tab', () {
    expect(
      categoriesWithActiveProducts(const [umum, minuman], [
        product(categoryId: minuman.id),
      ]),
      [minuman],
    );
  });

  test('kategori yang isinya hanya produk nonaktif tidak ikut jadi tab', () {
    expect(
      categoriesWithActiveProducts(const [minuman, gudang], [
        product(categoryId: minuman.id),
        product(id: 2, categoryId: gudang.id, isActive: false),
      ]),
      [minuman],
    );
  });

  test('satu produk aktif cukup walau sisanya nonaktif', () {
    expect(
      categoriesWithActiveProducts(const [gudang], [
        product(categoryId: gudang.id, isActive: false),
        product(id: 2, categoryId: gudang.id),
      ]),
      [gudang],
    );
  });

  /// Efek samping yang disengaja: 'Umum' hasil seed lenyap begitu semua produk
  /// punya kategori nyata. Terasa seperti kerusakan kalau tidak diharapkan.
  test('tidak ada kategori terpakai berarti tidak ada tab sama sekali', () {
    expect(categoriesWithActiveProducts(const [umum], const []), isEmpty);
  });

  test('urutan mengikuti daftar kategori, bukan urutan produk', () {
    expect(
      categoriesWithActiveProducts(const [umum, minuman, gudang], [
        product(categoryId: gudang.id),
        product(id: 2, categoryId: umum.id),
      ]),
      [umum, gudang],
    );
  });
}
