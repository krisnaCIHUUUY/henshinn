import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:henshin/features/product/domain/entities/product.dart';

part 'product_event.freezed.dart';

@freezed
class ProductEvent with _$ProductEvent {
  const factory ProductEvent.started() = ProductStarted;
  const factory ProductEvent.subscriptionRequested() =
      ProductSubscriptionRequested;
  const factory ProductEvent.categoriesRequested() =
      ProductCategoriesRequested;
  const factory ProductEvent.byCategoryRequested(int categoryId) =
      ProductByCategoryRequested;
  const factory ProductEvent.searchQueryChanged(String keyword) =
      ProductSearchQueryChanged;
  const factory ProductEvent.added(NewProduct product) = ProductAdded;
  const factory ProductEvent.updated(ProductEntity product) = ProductUpdated;
  const factory ProductEvent.deleted(int productId) = ProductDeleted;
  const factory ProductEvent.lowStockRequested() = ProductLowStockRequested;
  const factory ProductEvent.restocked(int productId, int qty, {String? note}) =
      ProductRestocked;
  const factory ProductEvent.stockAdjusted(
    int productId,
    int newStock, {
    String? note,
  }) = ProductStockAdjusted;
  const factory ProductEvent.barcodeScanned(String barcode) =
      ProductBarcodeScanned;
}
