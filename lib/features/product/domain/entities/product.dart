import 'package:equatable/equatable.dart';


class ProductEntity extends Equatable {
  final int id;
  final String name;
  final int price; // dalam rupiah utuh, hindari double
  final int stock;
  final int categoryId;
  final String? barcode;
  final String? imagePath;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.barcode,
    this.imagePath,
  });

  bool get isLowStock =>
      stock <= 5; // threshold sederhana, bisa dijadikan parameter nanti
  bool get isOutOfStock => stock <= 0;

  ProductEntity copyWith({
    int? id,
    String? name,
    int? price,
    int? stock,
    int? categoryId,
    String? barcode,
    String? imagePath,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
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
    stock,
    categoryId,
    barcode,
    imagePath,
  ];
}


class NewProduct extends Equatable {
  final String name;
  final int price;
  final int stock;
  final int categoryId;
  final String? barcode;
  final String? imagePath;

  const NewProduct({
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.barcode,
    this.imagePath,
  });

  @override
  List<Object?> get props => [
    name,
    price,
    stock,
    categoryId,
    barcode,
    imagePath,
  ];
}
