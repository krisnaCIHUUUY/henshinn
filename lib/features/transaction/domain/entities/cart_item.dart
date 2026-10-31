import 'package:equatable/equatable.dart';
import 'package:henshin/features/product/domain/entities/product.dart';

/// Satu baris keranjang. Hanya hidup di memori sampai dibayar — keranjang
/// tidak pernah disimpan ke DB (rencana langkah 6: "keranjang in-memory").
class CartItem extends Equatable {
  const CartItem({required this.product, required this.qty});

  final ProductEntity product;
  final int qty;

  int get subtotal => product.price * qty;

  /// Stok tidak cukup untuk qty ini. Dipakai UI untuk menandai barisnya
  /// sebelum kasir menekan Bayar; penolakan sebenarnya tetap di DB.
  bool get exceedsStock => qty > product.stock;

  CartItem copyWith({ProductEntity? product, int? qty}) =>
      CartItem(product: product ?? this.product, qty: qty ?? this.qty);

  @override
  List<Object?> get props => [product, qty];
}
