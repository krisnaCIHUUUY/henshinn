import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/category_dao.dart';
import 'package:henshin/core/database/dao/product_dao.dart';
import 'package:henshin/features/product/data/repositories/product_repository_impl.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';
import 'package:henshin/features/product/domain/usecases/add_product.dart';
import 'package:henshin/features/product/domain/usecases/delete_product.dart';
import 'package:henshin/features/product/domain/usecases/update_product.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/product/presentation/bloc/product_event.dart';
import 'package:henshin/features/product/presentation/bloc/product_state.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProductRepository repository;
  late ProductBloc bloc;

  const draft = NewProduct(
    name: 'Cappuccino',
    price: 25000,
    costPrice: 15000,
    stock: 10,
    categoryId: 1,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = ProductRepositoryImpl(ProductDao(db), CategoryDao(db));
    await db.select(db.categories).get(); // paksa seed kategori default
    bloc = ProductBloc(
      repository: repository,
      addProduct: AddProduct(repository),
      updateProduct: UpdateProduct(repository),
      deleteProduct: DeleteProduct(repository),
    );
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  /// Menunggu sampai state memenuhi syarat, bukan menebak jumlah emisi.
  Future<ProductState> waitFor(bool Function(ProductState) predicate) async {
    if (predicate(bloc.state)) return bloc.state;
    return bloc.stream.firstWhere(predicate).timeout(
      const Duration(seconds: 5),
    );
  }

  test('categoriesRequested mengisi state.categories', () async {
    // Ini yang dipakai dropdown kategori di form; kalau kosong, produk tidak
    // akan pernah bisa disimpan.
    bloc.add(const ProductEvent.categoriesRequested());

    final state = await waitFor((s) => s.categories.isNotEmpty);
    expect(state.categories.map((c) => c.name), [kDefaultCategoryName]);
    expect(state.categories.single.id, 1);
  });

  test('produk dan kategori bisa berlangganan bersamaan', () async {
    // Dua handler `emit.forEach` berjalan serentak — kalau salah satu memblokir
    // yang lain, form akan kehilangan salah satunya.
    bloc
      ..add(const ProductEvent.subscriptionRequested())
      ..add(const ProductEvent.categoriesRequested());

    final state = await waitFor(
      (s) => s.categories.isNotEmpty && s.status == ProductStatus.success,
    );
    expect(state.categories, hasLength(1));
    expect(state.products, isEmpty);
  });

  test('added lalu updated lalu deleted tercermin di state.products', () async {
    bloc.add(const ProductEvent.subscriptionRequested());
    await waitFor((s) => s.status == ProductStatus.success);

    bloc.add(const ProductEvent.added(draft));
    var state = await waitFor((s) => s.products.isNotEmpty);
    expect(state.products.single.name, 'Cappuccino');

    bloc.add(
      ProductEvent.updated(
        state.products.single.copyWith(name: 'Cappuccino Besar'),
      ),
    );
    state = await waitFor((s) => s.products.single.name == 'Cappuccino Besar');
    expect(state.products.single.name, 'Cappuccino Besar');

    bloc.add(ProductEvent.deleted(state.products.single.id));
    state = await waitFor((s) => s.products.isEmpty);
    expect(state.products, isEmpty);
  });

  test('simpan sukses tetap terdeteksi walau status sudah success', () async {
    // Regresi: layar form memakai perubahan state sebagai penanda "simpanan
    // saya selesai". Karena list sudah success dari langganan stream, emisi
    // success kedua tidak terlihat sebagai perubahan dan form tidak tertutup.
    bloc.add(const ProductEvent.subscriptionRequested());
    final before = await waitFor((s) => s.status == ProductStatus.success);
    expect(before.writeCount, 0);

    bloc.add(const ProductEvent.added(draft));
    final after = await waitFor((s) => s.writeCount == 1);

    expect(after.status, ProductStatus.success);

    // Produknya menyusul lewat emisi stream, bukan di emisi yang sama —
    // karena itu form boleh langsung menutup tanpa menunggu list.
    expect((await waitFor((s) => s.products.isNotEmpty)).products, hasLength(1));
  });

  test('simpan gagal juga menaikkan writeCount, bukan menggantung', () async {
    bloc.add(const ProductEvent.subscriptionRequested());
    await waitFor((s) => s.status == ProductStatus.success);

    bloc.add(
      const ProductEvent.added(
        NewProduct(name: '  ', price: 1000, categoryId: 1),
      ),
    );
    final after = await waitFor((s) => s.writeCount == 1);

    expect(after.status, ProductStatus.failure);
    expect(after.errorMessage, 'Nama produk tidak boleh kosong');
  });

  test('barcode kembar membuat status failure dengan pesan jelas', () async {
    bloc.add(const ProductEvent.subscriptionRequested());
    await waitFor((s) => s.status == ProductStatus.success);

    bloc.add(const ProductEvent.added(NewProduct(
      name: 'A',
      price: 1000,
      categoryId: 1,
      barcode: '111',
    )));
    await waitFor((s) => s.products.isNotEmpty);

    bloc.add(const ProductEvent.added(NewProduct(
      name: 'B',
      price: 2000,
      categoryId: 1,
      barcode: '111',
    )));
    final state = await waitFor((s) => s.status == ProductStatus.failure);

    expect(state.errorMessage, 'Barcode sudah dipakai produk lain');
    expect(state.products, hasLength(1));
  });

  test('nama kosong membuat status failure, produk tidak tersimpan', () async {
    bloc.add(const ProductEvent.subscriptionRequested());
    await waitFor((s) => s.status == ProductStatus.success);

    bloc.add(
      const ProductEvent.added(
        NewProduct(name: '  ', price: 1000, categoryId: 1),
      ),
    );
    final state = await waitFor((s) => s.status == ProductStatus.failure);

    expect(state.errorMessage, 'Nama produk tidak boleh kosong');
    expect(await repository.watchAllProducts().first, isEmpty);
  });
}
