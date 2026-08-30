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
