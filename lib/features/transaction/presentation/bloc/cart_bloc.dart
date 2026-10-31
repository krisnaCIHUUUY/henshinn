import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';
import 'package:henshin/features/transaction/domain/usecases/create_sale.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_event.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_state.dart';

/// Keranjang hidup di memori saja. Yang menyentuh DB hanya `checkedOut`,
/// lewat satu transaksi atomik di repository.
class CartBloc extends Bloc<CartEvent, CartState> {
  final CreateSale _createSale;

  CartBloc({required this._createSale}) : super(const CartState()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartQtyChanged>(_onQtyChanged);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCleared>(_onCleared);
    on<CartPaymentChanged>(_onPaymentChanged);
    on<CartCheckedOut>(_onCheckedOut);
  }

  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    final index = _indexOf(event.product.id);
    if (index == -1) {
      emit(
        _editing(
          [...state.items, CartItem(product: event.product, qty: 1)],
        ),
      );
      return;
    }

    final items = [...state.items];
    items[index] = items[index].copyWith(qty: items[index].qty + 1);
    emit(_editing(items));
  }

  void _onQtyChanged(CartQtyChanged event, Emitter<CartState> emit) {
    final index = _indexOf(event.productId);
    if (index == -1) return;

    // qty 0 atau kurang = hapus barisnya, bukan simpan nol
    if (event.qty <= 0) {
      emit(_editing([...state.items]..removeAt(index)));
      return;
    }

    final items = [...state.items];
    items[index] = items[index].copyWith(qty: event.qty);
    emit(_editing(items));
  }

  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    emit(
      _editing(
        state.items.where((item) => item.product.id != event.productId).toList(),
      ),
    );
  }

  void _onCleared(CartCleared event, Emitter<CartState> emit) {
    emit(const CartState());
  }

  void _onPaymentChanged(CartPaymentChanged event, Emitter<CartState> emit) {
    emit(
      state.copyWith(
        paymentAmount: event.amount,
        status: CartStatus.editing,
        errorMessage: '',
      ),
    );
  }

  Future<void> _onCheckedOut(
    CartCheckedOut event,
    Emitter<CartState> emit,
  ) async {
    if (state.items.isEmpty) return;
    emit(state.copyWith(status: CartStatus.saving, errorMessage: ''));

    final result = await _createSale(
      items: state.items,
      paymentAmount: state.paymentAmount,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CartStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      // Keranjang dikosongkan hanya setelah DB benar-benar menyimpan.
      (transactionId) => emit(
        CartState(status: CartStatus.saved, lastTransactionId: transactionId),
      ),
    );
  }

  int _indexOf(int productId) =>
      state.items.indexWhere((item) => item.product.id == productId);

  CartState _editing(List<CartItem> items) => state.copyWith(
    items: items,
    status: CartStatus.editing,
    errorMessage: '',
  );
}
