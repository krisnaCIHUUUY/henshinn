import 'package:drift/drift.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/features/product/domain/entities/product.dart';

class ProductModel {
  /// Konversi dari row Drift ke entity domain
  static ProductEntity toEntity(Product data) {
    return ProductEntity(
      id: data.id,
      name: data.name,
      price: data.price,
      stock: data.stock,
      categoryId: data.categoryId,
      barcode: data.barcode,
      imagePath: data.imagePath,
    );
  }

  /// Konversi dari entity domain ke companion (untuk insert/update Drift)
  static ProductsCompanion toCompanion(ProductEntity product) {
    return ProductsCompanion(
      id: Value(product.id),
      name: Value(product.name),
      price: Value(product.price),
      stock: Value(product.stock),
      categoryId: Value(product.categoryId),
      barcode: Value(product.barcode),
      imagePath: Value(product.imagePath),
    );
  }

  /// Untuk insert baru (tanpa id)
  static ProductsCompanion toInsertCompanion(NewProduct product) {
    return ProductsCompanion.insert(
      name: product.name,
      price: product.price,
      stock: Value(product.stock),
      categoryId: product.categoryId,
      barcode: Value(product.barcode),
      imagePath: Value(product.imagePath),
    );
  }
}
