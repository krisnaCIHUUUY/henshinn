// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProductEvent()';
}


}

/// @nodoc
class $ProductEventCopyWith<$Res>  {
$ProductEventCopyWith(ProductEvent _, $Res Function(ProductEvent) __);
}


/// Adds pattern-matching-related methods to [ProductEvent].
extension ProductEventPatterns on ProductEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProductStarted value)?  started,TResult Function( ProductSubscriptionRequested value)?  subscriptionRequested,TResult Function( ProductCategoriesRequested value)?  categoriesRequested,TResult Function( ProductByCategoryRequested value)?  byCategoryRequested,TResult Function( ProductSearchQueryChanged value)?  searchQueryChanged,TResult Function( ProductAdded value)?  added,TResult Function( ProductUpdated value)?  updated,TResult Function( ProductDeleted value)?  deleted,TResult Function( ProductLowStockRequested value)?  lowStockRequested,TResult Function( ProductRestocked value)?  restocked,TResult Function( ProductStockAdjusted value)?  stockAdjusted,TResult Function( ProductBarcodeScanned value)?  barcodeScanned,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProductStarted() when started != null:
return started(_that);case ProductSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case ProductCategoriesRequested() when categoriesRequested != null:
return categoriesRequested(_that);case ProductByCategoryRequested() when byCategoryRequested != null:
return byCategoryRequested(_that);case ProductSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that);case ProductAdded() when added != null:
return added(_that);case ProductUpdated() when updated != null:
return updated(_that);case ProductDeleted() when deleted != null:
return deleted(_that);case ProductLowStockRequested() when lowStockRequested != null:
return lowStockRequested(_that);case ProductRestocked() when restocked != null:
return restocked(_that);case ProductStockAdjusted() when stockAdjusted != null:
return stockAdjusted(_that);case ProductBarcodeScanned() when barcodeScanned != null:
return barcodeScanned(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProductStarted value)  started,required TResult Function( ProductSubscriptionRequested value)  subscriptionRequested,required TResult Function( ProductCategoriesRequested value)  categoriesRequested,required TResult Function( ProductByCategoryRequested value)  byCategoryRequested,required TResult Function( ProductSearchQueryChanged value)  searchQueryChanged,required TResult Function( ProductAdded value)  added,required TResult Function( ProductUpdated value)  updated,required TResult Function( ProductDeleted value)  deleted,required TResult Function( ProductLowStockRequested value)  lowStockRequested,required TResult Function( ProductRestocked value)  restocked,required TResult Function( ProductStockAdjusted value)  stockAdjusted,required TResult Function( ProductBarcodeScanned value)  barcodeScanned,}){
final _that = this;
switch (_that) {
case ProductStarted():
return started(_that);case ProductSubscriptionRequested():
return subscriptionRequested(_that);case ProductCategoriesRequested():
return categoriesRequested(_that);case ProductByCategoryRequested():
return byCategoryRequested(_that);case ProductSearchQueryChanged():
return searchQueryChanged(_that);case ProductAdded():
return added(_that);case ProductUpdated():
return updated(_that);case ProductDeleted():
return deleted(_that);case ProductLowStockRequested():
return lowStockRequested(_that);case ProductRestocked():
return restocked(_that);case ProductStockAdjusted():
return stockAdjusted(_that);case ProductBarcodeScanned():
return barcodeScanned(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProductStarted value)?  started,TResult? Function( ProductSubscriptionRequested value)?  subscriptionRequested,TResult? Function( ProductCategoriesRequested value)?  categoriesRequested,TResult? Function( ProductByCategoryRequested value)?  byCategoryRequested,TResult? Function( ProductSearchQueryChanged value)?  searchQueryChanged,TResult? Function( ProductAdded value)?  added,TResult? Function( ProductUpdated value)?  updated,TResult? Function( ProductDeleted value)?  deleted,TResult? Function( ProductLowStockRequested value)?  lowStockRequested,TResult? Function( ProductRestocked value)?  restocked,TResult? Function( ProductStockAdjusted value)?  stockAdjusted,TResult? Function( ProductBarcodeScanned value)?  barcodeScanned,}){
final _that = this;
switch (_that) {
case ProductStarted() when started != null:
return started(_that);case ProductSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case ProductCategoriesRequested() when categoriesRequested != null:
return categoriesRequested(_that);case ProductByCategoryRequested() when byCategoryRequested != null:
return byCategoryRequested(_that);case ProductSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that);case ProductAdded() when added != null:
return added(_that);case ProductUpdated() when updated != null:
return updated(_that);case ProductDeleted() when deleted != null:
return deleted(_that);case ProductLowStockRequested() when lowStockRequested != null:
return lowStockRequested(_that);case ProductRestocked() when restocked != null:
return restocked(_that);case ProductStockAdjusted() when stockAdjusted != null:
return stockAdjusted(_that);case ProductBarcodeScanned() when barcodeScanned != null:
return barcodeScanned(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  subscriptionRequested,TResult Function()?  categoriesRequested,TResult Function( int categoryId)?  byCategoryRequested,TResult Function( String keyword)?  searchQueryChanged,TResult Function( NewProduct product)?  added,TResult Function( ProductEntity product)?  updated,TResult Function( int productId)?  deleted,TResult Function()?  lowStockRequested,TResult Function( int productId,  int qty,  String? note)?  restocked,TResult Function( int productId,  int newStock,  String? note)?  stockAdjusted,TResult Function( String barcode)?  barcodeScanned,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProductStarted() when started != null:
return started();case ProductSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested();case ProductCategoriesRequested() when categoriesRequested != null:
return categoriesRequested();case ProductByCategoryRequested() when byCategoryRequested != null:
return byCategoryRequested(_that.categoryId);case ProductSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that.keyword);case ProductAdded() when added != null:
return added(_that.product);case ProductUpdated() when updated != null:
return updated(_that.product);case ProductDeleted() when deleted != null:
return deleted(_that.productId);case ProductLowStockRequested() when lowStockRequested != null:
return lowStockRequested();case ProductRestocked() when restocked != null:
return restocked(_that.productId,_that.qty,_that.note);case ProductStockAdjusted() when stockAdjusted != null:
return stockAdjusted(_that.productId,_that.newStock,_that.note);case ProductBarcodeScanned() when barcodeScanned != null:
return barcodeScanned(_that.barcode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  subscriptionRequested,required TResult Function()  categoriesRequested,required TResult Function( int categoryId)  byCategoryRequested,required TResult Function( String keyword)  searchQueryChanged,required TResult Function( NewProduct product)  added,required TResult Function( ProductEntity product)  updated,required TResult Function( int productId)  deleted,required TResult Function()  lowStockRequested,required TResult Function( int productId,  int qty,  String? note)  restocked,required TResult Function( int productId,  int newStock,  String? note)  stockAdjusted,required TResult Function( String barcode)  barcodeScanned,}) {final _that = this;
switch (_that) {
case ProductStarted():
return started();case ProductSubscriptionRequested():
return subscriptionRequested();case ProductCategoriesRequested():
return categoriesRequested();case ProductByCategoryRequested():
return byCategoryRequested(_that.categoryId);case ProductSearchQueryChanged():
return searchQueryChanged(_that.keyword);case ProductAdded():
return added(_that.product);case ProductUpdated():
return updated(_that.product);case ProductDeleted():
return deleted(_that.productId);case ProductLowStockRequested():
return lowStockRequested();case ProductRestocked():
return restocked(_that.productId,_that.qty,_that.note);case ProductStockAdjusted():
return stockAdjusted(_that.productId,_that.newStock,_that.note);case ProductBarcodeScanned():
return barcodeScanned(_that.barcode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  subscriptionRequested,TResult? Function()?  categoriesRequested,TResult? Function( int categoryId)?  byCategoryRequested,TResult? Function( String keyword)?  searchQueryChanged,TResult? Function( NewProduct product)?  added,TResult? Function( ProductEntity product)?  updated,TResult? Function( int productId)?  deleted,TResult? Function()?  lowStockRequested,TResult? Function( int productId,  int qty,  String? note)?  restocked,TResult? Function( int productId,  int newStock,  String? note)?  stockAdjusted,TResult? Function( String barcode)?  barcodeScanned,}) {final _that = this;
switch (_that) {
case ProductStarted() when started != null:
return started();case ProductSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested();case ProductCategoriesRequested() when categoriesRequested != null:
return categoriesRequested();case ProductByCategoryRequested() when byCategoryRequested != null:
return byCategoryRequested(_that.categoryId);case ProductSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that.keyword);case ProductAdded() when added != null:
return added(_that.product);case ProductUpdated() when updated != null:
return updated(_that.product);case ProductDeleted() when deleted != null:
return deleted(_that.productId);case ProductLowStockRequested() when lowStockRequested != null:
return lowStockRequested();case ProductRestocked() when restocked != null:
return restocked(_that.productId,_that.qty,_that.note);case ProductStockAdjusted() when stockAdjusted != null:
return stockAdjusted(_that.productId,_that.newStock,_that.note);case ProductBarcodeScanned() when barcodeScanned != null:
return barcodeScanned(_that.barcode);case _:
  return null;

}
}

}

/// @nodoc


class ProductStarted implements ProductEvent {
  const ProductStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProductEvent.started()';
}


}




/// @nodoc


class ProductSubscriptionRequested implements ProductEvent {
  const ProductSubscriptionRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductSubscriptionRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProductEvent.subscriptionRequested()';
}


}




/// @nodoc


class ProductCategoriesRequested implements ProductEvent {
  const ProductCategoriesRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductCategoriesRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProductEvent.categoriesRequested()';
}


}




/// @nodoc


class ProductByCategoryRequested implements ProductEvent {
  const ProductByCategoryRequested(this.categoryId);
  

 final  int categoryId;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductByCategoryRequestedCopyWith<ProductByCategoryRequested> get copyWith => _$ProductByCategoryRequestedCopyWithImpl<ProductByCategoryRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductByCategoryRequested&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId);

@override
String toString() {
  return 'ProductEvent.byCategoryRequested(categoryId: $categoryId)';
}


}

/// @nodoc
abstract mixin class $ProductByCategoryRequestedCopyWith<$Res> implements $ProductEventCopyWith<$Res> {
  factory $ProductByCategoryRequestedCopyWith(ProductByCategoryRequested value, $Res Function(ProductByCategoryRequested) _then) = _$ProductByCategoryRequestedCopyWithImpl;
@useResult
$Res call({
 int categoryId
});




}
/// @nodoc
class _$ProductByCategoryRequestedCopyWithImpl<$Res>
    implements $ProductByCategoryRequestedCopyWith<$Res> {
  _$ProductByCategoryRequestedCopyWithImpl(this._self, this._then);

  final ProductByCategoryRequested _self;
  final $Res Function(ProductByCategoryRequested) _then;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? categoryId = null,}) {
  return _then(ProductByCategoryRequested(
null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ProductSearchQueryChanged implements ProductEvent {
  const ProductSearchQueryChanged(this.keyword);
  

 final  String keyword;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductSearchQueryChangedCopyWith<ProductSearchQueryChanged> get copyWith => _$ProductSearchQueryChangedCopyWithImpl<ProductSearchQueryChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductSearchQueryChanged&&(identical(other.keyword, keyword) || other.keyword == keyword));
}


@override
int get hashCode => Object.hash(runtimeType,keyword);

@override
String toString() {
  return 'ProductEvent.searchQueryChanged(keyword: $keyword)';
}


}

/// @nodoc
abstract mixin class $ProductSearchQueryChangedCopyWith<$Res> implements $ProductEventCopyWith<$Res> {
  factory $ProductSearchQueryChangedCopyWith(ProductSearchQueryChanged value, $Res Function(ProductSearchQueryChanged) _then) = _$ProductSearchQueryChangedCopyWithImpl;
@useResult
$Res call({
 String keyword
});




}
/// @nodoc
class _$ProductSearchQueryChangedCopyWithImpl<$Res>
    implements $ProductSearchQueryChangedCopyWith<$Res> {
  _$ProductSearchQueryChangedCopyWithImpl(this._self, this._then);

  final ProductSearchQueryChanged _self;
  final $Res Function(ProductSearchQueryChanged) _then;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? keyword = null,}) {
  return _then(ProductSearchQueryChanged(
null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProductAdded implements ProductEvent {
  const ProductAdded(this.product);
  

 final  NewProduct product;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductAddedCopyWith<ProductAdded> get copyWith => _$ProductAddedCopyWithImpl<ProductAdded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductAdded&&(identical(other.product, product) || other.product == product));
}


@override
int get hashCode => Object.hash(runtimeType,product);

@override
String toString() {
  return 'ProductEvent.added(product: $product)';
}


}

/// @nodoc
abstract mixin class $ProductAddedCopyWith<$Res> implements $ProductEventCopyWith<$Res> {
  factory $ProductAddedCopyWith(ProductAdded value, $Res Function(ProductAdded) _then) = _$ProductAddedCopyWithImpl;
@useResult
$Res call({
 NewProduct product
});




}
/// @nodoc
class _$ProductAddedCopyWithImpl<$Res>
    implements $ProductAddedCopyWith<$Res> {
  _$ProductAddedCopyWithImpl(this._self, this._then);

  final ProductAdded _self;
  final $Res Function(ProductAdded) _then;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? product = null,}) {
  return _then(ProductAdded(
null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as NewProduct,
  ));
}


}

/// @nodoc


class ProductUpdated implements ProductEvent {
  const ProductUpdated(this.product);
  

 final  ProductEntity product;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductUpdatedCopyWith<ProductUpdated> get copyWith => _$ProductUpdatedCopyWithImpl<ProductUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductUpdated&&(identical(other.product, product) || other.product == product));
}


@override
int get hashCode => Object.hash(runtimeType,product);

@override
String toString() {
  return 'ProductEvent.updated(product: $product)';
}


}

/// @nodoc
abstract mixin class $ProductUpdatedCopyWith<$Res> implements $ProductEventCopyWith<$Res> {
  factory $ProductUpdatedCopyWith(ProductUpdated value, $Res Function(ProductUpdated) _then) = _$ProductUpdatedCopyWithImpl;
@useResult
$Res call({
 ProductEntity product
});




}
/// @nodoc
class _$ProductUpdatedCopyWithImpl<$Res>
    implements $ProductUpdatedCopyWith<$Res> {
  _$ProductUpdatedCopyWithImpl(this._self, this._then);

  final ProductUpdated _self;
  final $Res Function(ProductUpdated) _then;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? product = null,}) {
  return _then(ProductUpdated(
null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as ProductEntity,
  ));
}


}

/// @nodoc


class ProductDeleted implements ProductEvent {
  const ProductDeleted(this.productId);
  

 final  int productId;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductDeletedCopyWith<ProductDeleted> get copyWith => _$ProductDeletedCopyWithImpl<ProductDeleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductDeleted&&(identical(other.productId, productId) || other.productId == productId));
}


@override
int get hashCode => Object.hash(runtimeType,productId);

@override
String toString() {
  return 'ProductEvent.deleted(productId: $productId)';
}


}

/// @nodoc
abstract mixin class $ProductDeletedCopyWith<$Res> implements $ProductEventCopyWith<$Res> {
  factory $ProductDeletedCopyWith(ProductDeleted value, $Res Function(ProductDeleted) _then) = _$ProductDeletedCopyWithImpl;
@useResult
$Res call({
 int productId
});




}
/// @nodoc
class _$ProductDeletedCopyWithImpl<$Res>
    implements $ProductDeletedCopyWith<$Res> {
  _$ProductDeletedCopyWithImpl(this._self, this._then);

  final ProductDeleted _self;
  final $Res Function(ProductDeleted) _then;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,}) {
  return _then(ProductDeleted(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ProductLowStockRequested implements ProductEvent {
  const ProductLowStockRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductLowStockRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProductEvent.lowStockRequested()';
}


}




/// @nodoc


class ProductRestocked implements ProductEvent {
  const ProductRestocked(this.productId, this.qty, {this.note});
  

 final  int productId;
 final  int qty;
 final  String? note;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductRestockedCopyWith<ProductRestocked> get copyWith => _$ProductRestockedCopyWithImpl<ProductRestocked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductRestocked&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,productId,qty,note);

@override
String toString() {
  return 'ProductEvent.restocked(productId: $productId, qty: $qty, note: $note)';
}


}

/// @nodoc
abstract mixin class $ProductRestockedCopyWith<$Res> implements $ProductEventCopyWith<$Res> {
  factory $ProductRestockedCopyWith(ProductRestocked value, $Res Function(ProductRestocked) _then) = _$ProductRestockedCopyWithImpl;
@useResult
$Res call({
 int productId, int qty, String? note
});




}
/// @nodoc
class _$ProductRestockedCopyWithImpl<$Res>
    implements $ProductRestockedCopyWith<$Res> {
  _$ProductRestockedCopyWithImpl(this._self, this._then);

  final ProductRestocked _self;
  final $Res Function(ProductRestocked) _then;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? qty = null,Object? note = freezed,}) {
  return _then(ProductRestocked(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ProductStockAdjusted implements ProductEvent {
  const ProductStockAdjusted(this.productId, this.newStock, {this.note});
  

 final  int productId;
 final  int newStock;
 final  String? note;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductStockAdjustedCopyWith<ProductStockAdjusted> get copyWith => _$ProductStockAdjustedCopyWithImpl<ProductStockAdjusted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductStockAdjusted&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.newStock, newStock) || other.newStock == newStock)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,productId,newStock,note);

@override
String toString() {
  return 'ProductEvent.stockAdjusted(productId: $productId, newStock: $newStock, note: $note)';
}


}

/// @nodoc
abstract mixin class $ProductStockAdjustedCopyWith<$Res> implements $ProductEventCopyWith<$Res> {
  factory $ProductStockAdjustedCopyWith(ProductStockAdjusted value, $Res Function(ProductStockAdjusted) _then) = _$ProductStockAdjustedCopyWithImpl;
@useResult
$Res call({
 int productId, int newStock, String? note
});




}
/// @nodoc
class _$ProductStockAdjustedCopyWithImpl<$Res>
    implements $ProductStockAdjustedCopyWith<$Res> {
  _$ProductStockAdjustedCopyWithImpl(this._self, this._then);

  final ProductStockAdjusted _self;
  final $Res Function(ProductStockAdjusted) _then;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? newStock = null,Object? note = freezed,}) {
  return _then(ProductStockAdjusted(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,null == newStock ? _self.newStock : newStock // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ProductBarcodeScanned implements ProductEvent {
  const ProductBarcodeScanned(this.barcode);
  

 final  String barcode;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductBarcodeScannedCopyWith<ProductBarcodeScanned> get copyWith => _$ProductBarcodeScannedCopyWithImpl<ProductBarcodeScanned>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductBarcodeScanned&&(identical(other.barcode, barcode) || other.barcode == barcode));
}


@override
int get hashCode => Object.hash(runtimeType,barcode);

@override
String toString() {
  return 'ProductEvent.barcodeScanned(barcode: $barcode)';
}


}

/// @nodoc
abstract mixin class $ProductBarcodeScannedCopyWith<$Res> implements $ProductEventCopyWith<$Res> {
  factory $ProductBarcodeScannedCopyWith(ProductBarcodeScanned value, $Res Function(ProductBarcodeScanned) _then) = _$ProductBarcodeScannedCopyWithImpl;
@useResult
$Res call({
 String barcode
});




}
/// @nodoc
class _$ProductBarcodeScannedCopyWithImpl<$Res>
    implements $ProductBarcodeScannedCopyWith<$Res> {
  _$ProductBarcodeScannedCopyWithImpl(this._self, this._then);

  final ProductBarcodeScanned _self;
  final $Res Function(ProductBarcodeScanned) _then;

/// Create a copy of ProductEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? barcode = null,}) {
  return _then(ProductBarcodeScanned(
null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
