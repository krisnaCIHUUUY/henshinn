import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:henshin/features/product/domain/entities/product.dart';

part 'cart_event.freezed.dart';

@freezed
class CartEvent with _$CartEvent {
  /// Produk yang sudah ada di keranjang hanya menambah qty, tidak jadi baris baru.
  const factory CartEvent.itemAdded(ProductEntity product) = CartItemAdded;
  const factory CartEvent.qtyChanged(int productId, int qty) = CartQtyChanged;
  const factory CartEvent.itemRemoved(int productId) = CartItemRemoved;
  const factory CartEvent.cleared() = CartCleared;
  const factory CartEvent.paymentChanged(int amount) = CartPaymentChanged;
  const factory CartEvent.checkedOut() = CartCheckedOut;
}
