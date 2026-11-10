import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/theme/app_theme.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';
import 'package:henshin/features/product/domain/usecases/add_product.dart';
import 'package:henshin/features/product/domain/usecases/delete_product.dart';
import 'package:henshin/features/product/domain/usecases/update_product.dart';
import 'package:henshin/features/product/domain/usecases/watch_frequent_products.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:henshin/features/transaction/domain/usecases/create_sale.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_bloc.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_event.dart';
import 'package:henshin/features/transaction/presentation/screens/cashier_screen.dart';
import 'package:henshin/injection_container.dart';

/// Tes geometri, bukan tes data: semua repository dipalsukan dengan stream
/// kosong supaya tidak ada DB dan tidak ada stream Drift yang menggantung
/// (ADR-012). Yang diuji cuma satu hal — PayBar tidak boleh menelan body.
class _FakeProductRepository extends Fake implements ProductRepository {
  @override
  Stream<List<ProductEntity>> watchAllProducts() => Stream.value(const []);

  @override
  Stream<List<CategoryEntity>> watchCategories() => Stream.value(const []);

  @override
  Stream<List<ProductEntity>> watchLowStockProducts() =>
      Stream.value(const []);

  @override
  Stream<List<ProductEntity>> watchFrequentProducts() =>
      Stream.value(const []);
}

class _FakeTransactionRepository extends Fake
    implements TransactionRepository {}

void main() {
  const product = ProductEntity(
    id: 1,
    name: 'Mi Goreng Instan',
    price: 3500,
    costPrice: 2500,
    stock: 10,
    lowStockThreshold: 2,
    isActive: true,
    categoryId: 1,
  );

  late CartBloc cart;

  setUp(() {
    final repository = _FakeProductRepository();
    sl.registerLazySingleton<WatchFrequentProducts>(
      () => WatchFrequentProducts(repository),
    );
    cart = CartBloc(createSale: CreateSale(_FakeTransactionRepository()));
  });

  tearDown(() async {
    await cart.close();
    await sl.reset();
  });

  Future<void> pumpKasir(WidgetTester tester) async {
    final repository = _FakeProductRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ProductBloc>(
              create: (_) => ProductBloc(
                repository: repository,
                addProduct: AddProduct(repository),
                updateProduct: UpdateProduct(repository),
                deleteProduct: DeleteProduct(repository),
              ),
            ),
            BlocProvider<CartBloc>.value(value: cart),
          ],
          child: const CashierScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('keranjang kosong: daftar produk yang terlihat', (tester) async {
    await pumpKasir(tester);

    expect(find.text('Belum ada produk siap jual.'), findsOneWidget);
    expect(find.text('Bayar'), findsNothing);
  });

  testWidgets('keranjang terisi: PayBar tidak menelan body', (tester) async {
    cart.add(const CartEvent.itemAdded(product));
    await pumpKasir(tester);

    // Pernah rusak justru begini: Scaffold memberi bottomNavigationBar
    // batas longgar setinggi layar, dan satu Column mainAxisSize.max di
    // dalam PayBar memakan semuanya — body jadi 0 px, keranjang dan daftar
    // produk hilang sama sekali walau tombol Bayar tetap kelihatan.
    expect(find.text('Bayar'), findsOneWidget);
    expect(find.text('Keranjang · 1 produk'), findsOneWidget);
    expect(find.text('Mi Goreng Instan'), findsOneWidget);

    final screenHeight = tester.view.physicalSize.height /
        tester.view.devicePixelRatio;
    final payBar = tester.getRect(find.text('Rp 3.500').last);
    expect(
      payBar.bottom,
      greaterThan(screenHeight * 0.5),
      reason: 'PayBar harus menempel di bawah, bukan memenuhi layar',
    );
  });
}
