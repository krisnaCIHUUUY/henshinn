import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final int id;
  final String name;
  final int price;
  final int costPrice;
  final int stock;
  final int lowStockThreshold;
  final bool isActive;
  final int categoryId;
  final String? barcode;
  final String? imagePath;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.lowStockThreshold,
    required this.isActive,
    required this.categoryId,
    this.barcode,
    this.imagePath,
  });

  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;
  bool get isOutOfStock => stock <= 0;

  /// Laba per unit dari harga yang berlaku sekarang. Laporan tetap memakai
  /// snapshot di `transaction_items`, bukan angka ini.
  int get margin => price - costPrice;

  ProductEntity copyWith({
    int? id,
    String? name,
    int? price,
    int? costPrice,
    int? stock,
    int? lowStockThreshold,
    bool? isActive,
    int? categoryId,
    String? barcode,
    String? imagePath,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      categoryId: categoryId ?? this.categoryId,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    costPrice,
    stock,
    lowStockThreshold,
    isActive,
    categoryId,
    barcode,
    imagePath,
  ];
}

class NewProduct extends Equatable {
  final String name;
  final int price;
  final int costPrice;
  final int stock;
  final int lowStockThreshold;
  final bool isActive;
  final int categoryId;
  final String? barcode;
  final String? imagePath;

  const NewProduct({
    required this.name,
    required this.price,
    required this.categoryId,
    this.costPrice = 0,
    this.stock = 0,
    this.lowStockThreshold = 5,
    this.isActive = true,
    this.barcode,
    this.imagePath,
  });

  @override
  List<Object?> get props => [
    name,
    price,
    costPrice,
    stock,
    lowStockThreshold,
    isActive,
    categoryId,
    barcode,
    imagePath,
  ];
}

class CategoryEntity extends Equatable {
  final int id;
  final String name;

  const CategoryEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
