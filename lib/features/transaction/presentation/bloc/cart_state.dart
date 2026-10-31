import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';

part 'cart_state.freezed.dart';

enum CartStatus { editing, saving, saved, failure }

@freezed
abstract class CartState with _$CartState {
  const factory CartState({
    @Default([]) List<CartItem> items,
    @Default(0) int paymentAmount,
    @Default(CartStatus.editing) CartStatus status,
    @Default('') String errorMessage,

    /// Id transaksi yang baru tersimpan — dipakai layar untuk pindah ke struk.
    int? lastTransactionId,
  }) = _CartState;

  const CartState._();

  int get total => items.fold(0, (sum, item) => sum + item.subtotal);

  /// Negatif berarti uang kasir belum cukup.
  int get change => paymentAmount - total;

  int get itemCount => items.fold(0, (sum, item) => sum + item.qty);

  bool get hasStockProblem => items.any((item) => item.exceedsStock);

  /// Tombol Bayar hanya hidup kalau keranjang terisi dan uangnya cukup.
  bool get canCheckout =>
      items.isNotEmpty && change >= 0 && status != CartStatus.saving;
}
