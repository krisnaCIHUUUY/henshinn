import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/category_dao.dart';
import 'package:henshin/core/database/dao/product_dao.dart';
import 'package:henshin/features/product/data/repositories/product_repository_impl.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';
import 'package:henshin/features/product/domain/usecases/add_product.dart';
import 'package:henshin/features/product/domain/usecases/delete_product.dart';
import 'package:henshin/features/product/domain/usecases/update_product.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/product/presentation/screens/product_list_screen.dart';

/// Hanya memeriksa yang murni UI. Alur yang bolak-balik ke DB (simpan, ubah,
/// hapus) diuji di product_bloc_test.dart dan product_repository_impl_test.dart
/// dengan async nyata — di dalam `testWidgets` semuanya fake-async sehingga
/// stream Drift tidak maju dan `pumpAndSettle` habis waktu.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProductRepository repository;
  late ProductBloc bloc;

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

  Future<void> pumpList(WidgetTester tester) async {
    // Layar tes default 800x600 memotong form, dan ListView tidak membangun
    // widget di luar layar sehingga tombol Simpan tak bisa ditemukan.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const ProductListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('list kosong menampilkan ajakan menambah produk', (
    tester,
  ) async {
    await pumpList(tester);
    expect(find.textContaining('Belum ada produk'), findsOneWidget);
  });

  testWidgets('form menolak simpan kalau field wajib kosong', (tester) async {
    await pumpList(tester);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Produk'), findsWidgets);

    final save = find.widgetWithText(ElevatedButton, 'Simpan');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Nama produk wajib diisi'), findsOneWidget);
    expect(find.text('Wajib diisi'), findsWidgets);
    expect(find.text('Pilih kategori'), findsOneWidget);
    // form masih terbuka, tidak ada yang tersimpan
    expect(find.text('Tambah Produk'), findsWidgets);
  });
}
