// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductState {

 ProductStatus get status; List<ProductEntity> get products; List<ProductEntity> get searchResults; List<CategoryEntity> get categories; List<ProductEntity> get lowStockProducts; int get writeCount; String get errorMessage; ProductEntity? get scannedProduct;
/// Create a copy of ProductState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductStateCopyWith<ProductState> get copyWith => _$ProductStateCopyWithImpl<ProductState>(this as ProductState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.products, products)&&const DeepCollectionEquality().equals(other.searchResults, searchResults)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.lowStockProducts, lowStockProducts)&&(identical(other.writeCount, writeCount) || other.writeCount == writeCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.scannedProduct, scannedProduct) || other.scannedProduct == scannedProduct));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(products),const DeepCollectionEquality().hash(searchResults),const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(lowStockProducts),writeCount,errorMessage,scannedProduct);

@override
String toString() {
  return 'ProductState(status: $status, products: $products, searchResults: $searchResults, categories: $categories, lowStockProducts: $lowStockProducts, writeCount: $writeCount, errorMessage: $errorMessage, scannedProduct: $scannedProduct)';
}


}

/// @nodoc
abstract mixin class $ProductStateCopyWith<$Res>  {
  factory $ProductStateCopyWith(ProductState value, $Res Function(ProductState) _then) = _$ProductStateCopyWithImpl;
@useResult
$Res call({
 ProductStatus status, List<ProductEntity> products, List<ProductEntity> searchResults, List<CategoryEntity> categories, List<ProductEntity> lowStockProducts, int writeCount, String errorMessage, ProductEntity? scannedProduct
});




}
/// @nodoc
class _$ProductStateCopyWithImpl<$Res>
    implements $ProductStateCopyWith<$Res> {
  _$ProductStateCopyWithImpl(this._self, this._then);

  final ProductState _self;
  final $Res Function(ProductState) _then;

/// Create a copy of ProductState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? products = null,Object? searchResults = null,Object? categories = null,Object? lowStockProducts = null,Object? writeCount = null,Object? errorMessage = null,Object? scannedProduct = freezed,}) {
  return _then(ProductState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProductStatus,products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<ProductEntity>,searchResults: null == searchResults ? _self.searchResults : searchResults // ignore: cast_nullable_to_non_nullable
as List<ProductEntity>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryEntity>,lowStockProducts: null == lowStockProducts ? _self.lowStockProducts : lowStockProducts // ignore: cast_nullable_to_non_nullable
as List<ProductEntity>,writeCount: null == writeCount ? _self.writeCount : writeCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,scannedProduct: freezed == scannedProduct ? _self.scannedProduct : scannedProduct // ignore: cast_nullable_to_non_nullable
as ProductEntity?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductState].
extension ProductStatePatterns on ProductState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductState value)  $default,){
final _that = this;
switch (_that) {
case _ProductState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductState value)?  $default,){
final _that = this;
switch (_that) {
case _ProductState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProductStatus status,  List<ProductEntity> products,  List<ProductEntity> searchResults,  List<CategoryEntity> categories,  List<ProductEntity> lowStockProducts,  int writeCount,  String errorMessage,  ProductEntity? scannedProduct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductState() when $default != null:
return $default(_that.status,_that.products,_that.searchResults,_that.categories,_that.lowStockProducts,_that.writeCount,_that.errorMessage,_that.scannedProduct);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProductStatus status,  List<ProductEntity> products,  List<ProductEntity> searchResults,  List<CategoryEntity> categories,  List<ProductEntity> lowStockProducts,  int writeCount,  String errorMessage,  ProductEntity? scannedProduct)  $default,) {final _that = this;
switch (_that) {
case _ProductState():
return $default(_that.status,_that.products,_that.searchResults,_that.categories,_that.lowStockProducts,_that.writeCount,_that.errorMessage,_that.scannedProduct);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProductStatus status,  List<ProductEntity> products,  List<ProductEntity> searchResults,  List<CategoryEntity> categories,  List<ProductEntity> lowStockProducts,  int writeCount,  String errorMessage,  ProductEntity? scannedProduct)?  $default,) {final _that = this;
switch (_that) {
case _ProductState() when $default != null:
return $default(_that.status,_that.products,_that.searchResults,_that.categories,_that.lowStockProducts,_that.writeCount,_that.errorMessage,_that.scannedProduct);case _:
  return null;

}
}

}

/// @nodoc


class _ProductState implements ProductState {
  const _ProductState({this.status = ProductStatus.initial,  List<ProductEntity> products = const [],  List<ProductEntity> searchResults = const [],  List<CategoryEntity> categories = const [],  List<ProductEntity> lowStockProducts = const [], this.writeCount = 0, this.errorMessage = '', this.scannedProduct}): _products = products,_searchResults = searchResults,_categories = categories,_lowStockProducts = lowStockProducts;
  

@override@JsonKey() final  ProductStatus status;
 final  List<ProductEntity> _products;
@override@JsonKey() List<ProductEntity> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}

 final  List<ProductEntity> _searchResults;
@override@JsonKey() List<ProductEntity> get searchResults {
  if (_searchResults is EqualUnmodifiableListView) return _searchResults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchResults);
}

 final  List<CategoryEntity> _categories;
@override@JsonKey() List<CategoryEntity> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<ProductEntity> _lowStockProducts;
@override@JsonKey() List<ProductEntity> get lowStockProducts {
  if (_lowStockProducts is EqualUnmodifiableListView) return _lowStockProducts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lowStockProducts);
}

@override@JsonKey() final  int writeCount;
@override@JsonKey() final  String errorMessage;
@override final  ProductEntity? scannedProduct;

/// Create a copy of ProductState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductStateCopyWith<_ProductState> get copyWith => __$ProductStateCopyWithImpl<_ProductState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._products, _products)&&const DeepCollectionEquality().equals(other._searchResults, _searchResults)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._lowStockProducts, _lowStockProducts)&&(identical(other.writeCount, writeCount) || other.writeCount == writeCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.scannedProduct, scannedProduct) || other.scannedProduct == scannedProduct));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_products),const DeepCollectionEquality().hash(_searchResults),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_lowStockProducts),writeCount,errorMessage,scannedProduct);

@override
String toString() {
  return 'ProductState(status: $status, products: $products, searchResults: $searchResults, categories: $categories, lowStockProducts: $lowStockProducts, writeCount: $writeCount, errorMessage: $errorMessage, scannedProduct: $scannedProduct)';
}


}

/// @nodoc
abstract mixin class _$ProductStateCopyWith<$Res> implements $ProductStateCopyWith<$Res> {
  factory _$ProductStateCopyWith(_ProductState value, $Res Function(_ProductState) _then) = __$ProductStateCopyWithImpl;
@override @useResult
$Res call({
 ProductStatus status, List<ProductEntity> products, List<ProductEntity> searchResults, List<CategoryEntity> categories, List<ProductEntity> lowStockProducts, int writeCount, String errorMessage, ProductEntity? scannedProduct
});




}
/// @nodoc
class __$ProductStateCopyWithImpl<$Res>
    implements _$ProductStateCopyWith<$Res> {
  __$ProductStateCopyWithImpl(this._self, this._then);

  final _ProductState _self;
  final $Res Function(_ProductState) _then;

/// Create a copy of ProductState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? products = null,Object? searchResults = null,Object? categories = null,Object? lowStockProducts = null,Object? writeCount = null,Object? errorMessage = null,Object? scannedProduct = freezed,}) {
  return _then(_ProductState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProductStatus,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<ProductEntity>,searchResults: null == searchResults ? _self._searchResults : searchResults // ignore: cast_nullable_to_non_nullable
as List<ProductEntity>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryEntity>,lowStockProducts: null == lowStockProducts ? _self._lowStockProducts : lowStockProducts // ignore: cast_nullable_to_non_nullable
as List<ProductEntity>,writeCount: null == writeCount ? _self.writeCount : writeCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,scannedProduct: freezed == scannedProduct ? _self.scannedProduct : scannedProduct // ignore: cast_nullable_to_non_nullable
as ProductEntity?,
  ));
}


}

// dart format on
