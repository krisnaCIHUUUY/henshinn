import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
part 'product_state.freezed.dart';

enum ProductStatus { initial, loading, success, failure }

@freezed
abstract class ProductState with _$ProductState {
  const factory ProductState({
    @Default(ProductStatus.initial) ProductStatus status,
    @Default([]) List<ProductEntity> products,
    @Default([]) List<ProductEntity> searchResults,
    @Default([]) List<CategoryEntity> categories,
    @Default([]) List<ProductEntity> lowStockProducts,
    // Naik tiap satu operasi tulis selesai (sukses maupun gagal). Layar form
    // memakai ini sebagai penanda "simpanan saya selesai": `status` saja tidak
    // cukup karena list sudah bernilai success dari langganan stream, jadi
    // emisi success kedua tidak terlihat sebagai perubahan.
    @Default(0) int writeCount,
    @Default('') String errorMessage,
    ProductEntity? scannedProduct,
  }) = _ProductState;

  // @override
  // String get errorMessage => errorMessage;

  // @override
  // List<ProductEntity> get products => products;

  // @override
  // ProductEntity? get scannedProduct => scannedProduct;

  // @override
  // List<ProductEntity> get searchResults => searchResults;

  // @override
  // ProductStatus get status => status;
}
