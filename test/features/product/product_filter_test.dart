import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/presentation/screens/product_list_screen.dart';

/// Chip `Semua` / `Perlu restok · N` / `<kategori>` + kolom cari layar Produk.
/// Logikanya fungsi murni, jadi diuji `test()` biasa — bukan lewat widget
/// (ADR-012).
void main() {
  ProductEntity product({
    required int id,
    String name = 'Produk',
    int categoryId = 1,
    int stock = 10,
    String? barcode,
  }) => ProductEntity(
    id: id,
    name: name,
    barcode: barcode,
    price: 5000,
    costPrice: 3000,
    stock: stock,
    lowStockThreshold: 2,
    isActive: true,
    categoryId: categoryId,
  );

  final mi = product(id: 1, name: 'Mi Goreng Instan', categoryId: 1);
  final teh = product(
    id: 2,
    name: 'Teh Botol 350 ml',
    categoryId: 2,
    stock: 1,
    barcode: '8991002',
  );
  final beras = product(id: 3, name: 'Beras 5 kg', categoryId: 1, stock: 0);

  final semua = [mi, teh, beras];

  /// Daftar dari query `watchLowStockProducts`, bukan hitungan ulang: query itu
  /// memasukkan stok 0 juga, sementara getter `isLowStock` di entity tidak.
  final perluRestok = [beras, teh];

  test('Semua: tidak ada yang disaring', () {
    expect(
      visibleProducts(
        products: semua,
        lowStock: perluRestok,
        lowStockOnly: false,
      ),
      semua,
    );
  });

  test('Perlu restok memakai daftar low-stock, bukan daftar penuh', () {
    expect(
      visibleProducts(
        products: semua,
        lowStock: perluRestok,
        lowStockOnly: true,
      ),
      perluRestok,
    );
  });

  test('Perlu restok memuat produk yang stoknya sudah 0', () {
    expect(
      visibleProducts(
        products: semua,
        lowStock: perluRestok,
        lowStockOnly: true,
      ),
      contains(beras),
    );
  });

  test('chip kategori hanya menyisakan kategori itu', () {
    expect(
      visibleProducts(
        products: semua,
        lowStock: perluRestok,
        lowStockOnly: false,
        categoryId: 2,
      ),
      [teh],
    );
  });

  test('kata kunci mencocokkan nama tanpa peduli huruf besar-kecil', () {
    expect(
      visibleProducts(
        products: semua,
        lowStock: perluRestok,
        lowStockOnly: false,
        keyword: 'bOtOl',
      ),
      [teh],
    );
  });

  test('kata kunci juga mencocokkan barcode', () {
    expect(
      visibleProducts(
        products: semua,
        lowStock: perluRestok,
        lowStockOnly: false,
        keyword: '8991002',
      ),
      [teh],
    );
  });

  test('kata kunci kosong atau hanya spasi tidak menyaring apa pun', () {
    expect(
      visibleProducts(
        products: semua,
        lowStock: perluRestok,
        lowStockOnly: false,
        keyword: '   ',
      ),
      semua,
    );
  });

  test('kata kunci yang tidak cocok menghasilkan daftar kosong', () {
    expect(
      visibleProducts(
        products: semua,
        lowStock: perluRestok,
        lowStockOnly: false,
        keyword: 'kopi',
      ),
      isEmpty,
    );
  });

  test('cari tetap berlaku di dalam chip Perlu restok', () {
    expect(
      visibleProducts(
        products: semua,
        lowStock: perluRestok,
        lowStockOnly: true,
        keyword: 'beras',
      ),
      [beras],
    );
  });
}
