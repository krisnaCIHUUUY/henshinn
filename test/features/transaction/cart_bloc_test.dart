import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';
import 'package:henshin/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:henshin/features/transaction/domain/usecases/create_sale.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_bloc.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_event.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_state.dart';

class _FakeTransactionRepository implements TransactionRepository {
  Failure? failure;
  List<CartItem>? lastItems;
  int? lastPayment;

  @override
  Future<Either<Failure, int>> createSale({
    required List<CartItem> items,
    required int paymentAmount,
  }) async {
    lastItems = items;
    lastPayment = paymentAmount;
    final f = failure;
    return f != null ? Left(f) : const Right(77);
  }
}

ProductEntity product({
  int id = 1,
  String name = 'Kopi',
  int price = 25000,
  int stock = 10,
}) => ProductEntity(
  id: id,
  name: name,
  price: price,
  costPrice: 15000,
  stock: stock,
  lowStockThreshold: 5,
  isActive: true,
  categoryId: 1,
);

void main() {
  late _FakeTransactionRepository repository;
  late CartBloc bloc;

  setUp(() {
    repository = _FakeTransactionRepository();
    bloc = CartBloc(createSale: CreateSale(repository));
  });

  tearDown(() => bloc.close());

  group('isi keranjang', () {
    test('produk yang sama menambah qty, bukan baris baru', () async {
      final kopi = product();
      bloc
        ..add(CartEvent.itemAdded(kopi))
        ..add(CartEvent.itemAdded(kopi))
        ..add(CartEvent.itemAdded(product(id: 2, name: 'Teh', price: 8000)));

      final state = await bloc.stream.firstWhere((s) => s.items.length == 2);
      expect(state.items.first.qty, 2);
      expect(state.itemCount, 3);
    });

    test('total dan kembalian dihitung otomatis', () async {
      bloc
        ..add(CartEvent.itemAdded(product())) // 25000
        ..add(CartEvent.itemAdded(product(id: 2, name: 'Teh', price: 8000)))
        ..add(const CartEvent.paymentChanged(50000));

      await bloc.stream.firstWhere((s) => s.paymentAmount == 50000);
      expect(bloc.state.total, 33000);
      expect(bloc.state.change, 17000);
      expect(bloc.state.canCheckout, isTrue);
    });

    test('qty 0 menghapus barisnya, tidak menyimpan nol', () async {
      bloc.add(CartEvent.itemAdded(product()));
      await bloc.stream.firstWhere((s) => s.items.isNotEmpty);

      bloc.add(const CartEvent.qtyChanged(1, 0));
      await bloc.stream.firstWhere((s) => s.items.isEmpty);
      expect(bloc.state.items, isEmpty);
    });

    test('hapus dan kosongkan keranjang', () async {
      bloc
        ..add(CartEvent.itemAdded(product()))
        ..add(CartEvent.itemAdded(product(id: 2, name: 'Teh')));
      await bloc.stream.firstWhere((s) => s.items.length == 2);

      bloc.add(const CartEvent.itemRemoved(1));
      await bloc.stream.firstWhere((s) => s.items.length == 1);
      expect(bloc.state.items.single.product.id, 2);

      bloc.add(const CartEvent.cleared());
      await bloc.stream.firstWhere((s) => s.items.isEmpty);
      expect(bloc.state.paymentAmount, 0);
    });

    test('qty di atas stok ditandai, tapi tidak diblokir di keranjang',
        () async {
      bloc.add(CartEvent.itemAdded(product(stock: 1)));
      await bloc.stream.firstWhere((s) => s.items.isNotEmpty);

      bloc.add(const CartEvent.qtyChanged(1, 5));
      await bloc.stream.firstWhere((s) => s.items.single.qty == 5);

      expect(bloc.state.hasStockProblem, isTrue);
      // penolakan sebenarnya di DB; keranjang hanya memberi tanda
      expect(bloc.state.canCheckout, isFalse, reason: 'uang belum diisi');
    });
  });

  group('tombol Bayar', () {
    test('mati saat keranjang kosong atau uang kurang', () async {
      expect(bloc.state.canCheckout, isFalse);

      bloc
        ..add(CartEvent.itemAdded(product())) // total 25000
        ..add(const CartEvent.paymentChanged(10000));
      await bloc.stream.firstWhere((s) => s.paymentAmount == 10000);

      expect(bloc.state.change, -15000);
      expect(bloc.state.canCheckout, isFalse);
    });

    test('uang tepat sama dengan total boleh dibayar', () async {
      bloc
        ..add(CartEvent.itemAdded(product()))
        ..add(const CartEvent.paymentChanged(25000));
      await bloc.stream.firstWhere((s) => s.paymentAmount == 25000);

      expect(bloc.state.change, 0);
      expect(bloc.state.canCheckout, isTrue);
    });
  });

  group('checkout', () {
    test('sukses mengosongkan keranjang dan menyimpan id transaksi', () async {
      bloc
        ..add(CartEvent.itemAdded(product()))
        ..add(const CartEvent.paymentChanged(50000))
        ..add(const CartEvent.checkedOut());

      final state = await bloc.stream.firstWhere(
        (s) => s.status == CartStatus.saved,
      );

      expect(state.lastTransactionId, 77);
      expect(state.items, isEmpty, reason: 'keranjang direset setelah sukses');
      expect(repository.lastPayment, 50000);
      expect(repository.lastItems, hasLength(1));
    });

    test('gagal menahan keranjang supaya kasir bisa coba lagi', () async {
      repository.failure = const ValidationFailure('Stok Kopi tinggal 1');

      bloc
        ..add(CartEvent.itemAdded(product()))
        ..add(const CartEvent.paymentChanged(50000))
        ..add(const CartEvent.checkedOut());

      final state = await bloc.stream.firstWhere(
        (s) => s.status == CartStatus.failure,
      );

      expect(state.errorMessage, 'Stok Kopi tinggal 1');
      // ini yang penting: isi keranjang tidak hilang saat gagal
      expect(state.items, hasLength(1));
      expect(state.paymentAmount, 50000);
    });

    test('checkout saat keranjang kosong tidak memanggil repository',
        () async {
      bloc.add(const CartEvent.checkedOut());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.lastItems, isNull);
      expect(bloc.state.status, CartStatus.editing);
    });
  });
}
