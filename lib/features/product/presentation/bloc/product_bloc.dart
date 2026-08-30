import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';
import 'package:henshin/features/product/domain/usecases/add_product.dart';
import 'package:henshin/features/product/domain/usecases/delete_product.dart';
import 'package:henshin/features/product/domain/usecases/update_product.dart';
import 'package:henshin/features/product/presentation/bloc/product_event.dart';
import 'package:henshin/features/product/presentation/bloc/product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;
  final AddProduct _addProduct;
  final UpdateProduct _updateProduct;
  final DeleteProduct _deleteProduct;

  StreamSubscription? _productSubscription;

  ProductBloc({
    required this._repository,
    required this._addProduct,
    required this._updateProduct,
    required this._deleteProduct,
  }) : super(const ProductState()) {
    on<ProductSubscriptionRequested>(_onSubscriptionRequested);
    on<ProductByCategoryRequested>(_onByCategoryRequested);
    on<ProductSearchQueryChanged>(_onSearchQueryChanged);
    on<ProductAdded>(_onAdded);
    on<ProductUpdated>(_onUpdated);
    on<ProductDeleted>(_onDeleted);
    on<ProductBarcodeScanned>(_onBarcodeScanned);
  }

  Future<void> _onSubscriptionRequested(
    ProductSubscriptionRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.loading));

    await emit.forEach(
      _repository.watchAllProducts(),
      onData: (products) =>
          state.copyWith(status: ProductStatus.success, products: products),
      onError: (error, stackTrace) => state.copyWith(
        status: ProductStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onByCategoryRequested(
    ProductByCategoryRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.loading));

    await emit.forEach(
      _repository.watchProductsByCategory(event.categoryId),
      onData: (products) =>
          state.copyWith(status: ProductStatus.success, products: products),
      onError: (error, stackTrace) => state.copyWith(
        status: ProductStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onSearchQueryChanged(
    ProductSearchQueryChanged event,
    Emitter<ProductState> emit,
  ) async {
    if (event.keyword.isEmpty) {
      emit(state.copyWith(searchResults: []));
      return;
    }

    final result = await _repository.searchProducts(event.keyword);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProductStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (products) => emit(
        state.copyWith(status: ProductStatus.success, searchResults: products),
      ),
    );
  }

  Future<void> _onAdded(ProductAdded event, Emitter<ProductState> emit) async {
    final result = await _addProduct(event.product);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProductStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: ProductStatus.success)),
    );
    // list otomatis ter-update lewat stream subscription, tidak perlu emit ulang list
  }

  Future<void> _onUpdated(
    ProductUpdated event,
    Emitter<ProductState> emit,
  ) async {
    final result = await _updateProduct(event.product);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProductStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: ProductStatus.success)),
    );
  }

  Future<void> _onDeleted(
    ProductDeleted event,
    Emitter<ProductState> emit,
  ) async {
    final result = await _deleteProduct(event.productId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProductStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: ProductStatus.success)),
    );
  }

  Future<void> _onBarcodeScanned(
    ProductBarcodeScanned event,
    Emitter<ProductState> emit,
  ) async {
    final result = await _repository.getProductByBarcode(event.barcode);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProductStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (product) => emit(state.copyWith(scannedProduct: product)),
    );
  }

  @override
  Future<void> close() {
    _productSubscription?.cancel();
    return super.close();
  }
}
