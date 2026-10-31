import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/errors/failures.dart';
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
    on<ProductCategoriesRequested>(_onCategoriesRequested);
    on<ProductByCategoryRequested>(_onByCategoryRequested);
    on<ProductSearchQueryChanged>(_onSearchQueryChanged);
    on<ProductAdded>(_onAdded);
    on<ProductUpdated>(_onUpdated);
    on<ProductDeleted>(_onDeleted);
    on<ProductLowStockRequested>(_onLowStockRequested);
    on<ProductRestocked>(_onRestocked);
    on<ProductStockAdjusted>(_onStockAdjusted);
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

  /// Handler terpisah dari produk supaya dua stream bisa jalan bersamaan;
  /// `emit.forEach` menahan handler-nya sampai stream selesai.
  Future<void> _onCategoriesRequested(
    ProductCategoriesRequested event,
    Emitter<ProductState> emit,
  ) async {
    await emit.forEach(
      _repository.watchCategories(),
      onData: (categories) => state.copyWith(categories: categories),
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

  // list otomatis ter-update lewat stream subscription, tidak perlu emit list
  Future<void> _onAdded(ProductAdded event, Emitter<ProductState> emit) async {
    _emitResult(await _addProduct(event.product), emit);
  }

  Future<void> _onUpdated(
    ProductUpdated event,
    Emitter<ProductState> emit,
  ) async {
    _emitResult(await _updateProduct(event.product), emit);
  }

  Future<void> _onDeleted(
    ProductDeleted event,
    Emitter<ProductState> emit,
  ) async {
    _emitResult(await _deleteProduct(event.productId), emit);
  }

  Future<void> _onLowStockRequested(
    ProductLowStockRequested event,
    Emitter<ProductState> emit,
  ) async {
    await emit.forEach(
      _repository.watchLowStockProducts(),
      onData: (products) => state.copyWith(lowStockProducts: products),
      onError: (error, stackTrace) => state.copyWith(
        status: ProductStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onRestocked(
    ProductRestocked event,
    Emitter<ProductState> emit,
  ) async {
    final result = await _repository.restock(
      event.productId,
      event.qty,
      note: event.note,
    );
    _emitResult(result, emit);
  }

  Future<void> _onStockAdjusted(
    ProductStockAdjusted event,
    Emitter<ProductState> emit,
  ) async {
    final result = await _repository.adjustStock(
      event.productId,
      event.newStock,
      note: event.note,
    );
    _emitResult(result, emit);
  }

  /// Satu-satunya tempat hasil operasi tulis di-emit. `writeCount` selalu
  /// naik bersama status, jadi pemanggil bisa membedakan "write saya selesai"
  /// dari emisi stream list yang kebetulan juga bernilai success.
  void _emitResult(Either<Failure, void> result, Emitter<ProductState> emit) {
    final writeCount = state.writeCount + 1;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProductStatus.failure,
          errorMessage: failure.message,
          writeCount: writeCount,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: ProductStatus.success,
          errorMessage: '',
          writeCount: writeCount,
        ),
      ),
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
