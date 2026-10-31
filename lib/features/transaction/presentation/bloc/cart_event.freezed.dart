// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CartEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CartEvent()';
}


}

/// @nodoc
class $CartEventCopyWith<$Res>  {
$CartEventCopyWith(CartEvent _, $Res Function(CartEvent) __);
}


/// Adds pattern-matching-related methods to [CartEvent].
extension CartEventPatterns on CartEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CartItemAdded value)?  itemAdded,TResult Function( CartQtyChanged value)?  qtyChanged,TResult Function( CartItemRemoved value)?  itemRemoved,TResult Function( CartCleared value)?  cleared,TResult Function( CartPaymentChanged value)?  paymentChanged,TResult Function( CartCheckedOut value)?  checkedOut,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CartItemAdded() when itemAdded != null:
return itemAdded(_that);case CartQtyChanged() when qtyChanged != null:
return qtyChanged(_that);case CartItemRemoved() when itemRemoved != null:
return itemRemoved(_that);case CartCleared() when cleared != null:
return cleared(_that);case CartPaymentChanged() when paymentChanged != null:
return paymentChanged(_that);case CartCheckedOut() when checkedOut != null:
return checkedOut(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CartItemAdded value)  itemAdded,required TResult Function( CartQtyChanged value)  qtyChanged,required TResult Function( CartItemRemoved value)  itemRemoved,required TResult Function( CartCleared value)  cleared,required TResult Function( CartPaymentChanged value)  paymentChanged,required TResult Function( CartCheckedOut value)  checkedOut,}){
final _that = this;
switch (_that) {
case CartItemAdded():
return itemAdded(_that);case CartQtyChanged():
return qtyChanged(_that);case CartItemRemoved():
return itemRemoved(_that);case CartCleared():
return cleared(_that);case CartPaymentChanged():
return paymentChanged(_that);case CartCheckedOut():
return checkedOut(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CartItemAdded value)?  itemAdded,TResult? Function( CartQtyChanged value)?  qtyChanged,TResult? Function( CartItemRemoved value)?  itemRemoved,TResult? Function( CartCleared value)?  cleared,TResult? Function( CartPaymentChanged value)?  paymentChanged,TResult? Function( CartCheckedOut value)?  checkedOut,}){
final _that = this;
switch (_that) {
case CartItemAdded() when itemAdded != null:
return itemAdded(_that);case CartQtyChanged() when qtyChanged != null:
return qtyChanged(_that);case CartItemRemoved() when itemRemoved != null:
return itemRemoved(_that);case CartCleared() when cleared != null:
return cleared(_that);case CartPaymentChanged() when paymentChanged != null:
return paymentChanged(_that);case CartCheckedOut() when checkedOut != null:
return checkedOut(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ProductEntity product)?  itemAdded,TResult Function( int productId,  int qty)?  qtyChanged,TResult Function( int productId)?  itemRemoved,TResult Function()?  cleared,TResult Function( int amount)?  paymentChanged,TResult Function()?  checkedOut,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CartItemAdded() when itemAdded != null:
return itemAdded(_that.product);case CartQtyChanged() when qtyChanged != null:
return qtyChanged(_that.productId,_that.qty);case CartItemRemoved() when itemRemoved != null:
return itemRemoved(_that.productId);case CartCleared() when cleared != null:
return cleared();case CartPaymentChanged() when paymentChanged != null:
return paymentChanged(_that.amount);case CartCheckedOut() when checkedOut != null:
return checkedOut();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ProductEntity product)  itemAdded,required TResult Function( int productId,  int qty)  qtyChanged,required TResult Function( int productId)  itemRemoved,required TResult Function()  cleared,required TResult Function( int amount)  paymentChanged,required TResult Function()  checkedOut,}) {final _that = this;
switch (_that) {
case CartItemAdded():
return itemAdded(_that.product);case CartQtyChanged():
return qtyChanged(_that.productId,_that.qty);case CartItemRemoved():
return itemRemoved(_that.productId);case CartCleared():
return cleared();case CartPaymentChanged():
return paymentChanged(_that.amount);case CartCheckedOut():
return checkedOut();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ProductEntity product)?  itemAdded,TResult? Function( int productId,  int qty)?  qtyChanged,TResult? Function( int productId)?  itemRemoved,TResult? Function()?  cleared,TResult? Function( int amount)?  paymentChanged,TResult? Function()?  checkedOut,}) {final _that = this;
switch (_that) {
case CartItemAdded() when itemAdded != null:
return itemAdded(_that.product);case CartQtyChanged() when qtyChanged != null:
return qtyChanged(_that.productId,_that.qty);case CartItemRemoved() when itemRemoved != null:
return itemRemoved(_that.productId);case CartCleared() when cleared != null:
return cleared();case CartPaymentChanged() when paymentChanged != null:
return paymentChanged(_that.amount);case CartCheckedOut() when checkedOut != null:
return checkedOut();case _:
  return null;

}
}

}

/// @nodoc


class CartItemAdded implements CartEvent {
  const CartItemAdded(this.product);
  

 final  ProductEntity product;

/// Create a copy of CartEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartItemAddedCopyWith<CartItemAdded> get copyWith => _$CartItemAddedCopyWithImpl<CartItemAdded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartItemAdded&&(identical(other.product, product) || other.product == product));
}


@override
int get hashCode => Object.hash(runtimeType,product);

@override
String toString() {
  return 'CartEvent.itemAdded(product: $product)';
}


}

/// @nodoc
abstract mixin class $CartItemAddedCopyWith<$Res> implements $CartEventCopyWith<$Res> {
  factory $CartItemAddedCopyWith(CartItemAdded value, $Res Function(CartItemAdded) _then) = _$CartItemAddedCopyWithImpl;
@useResult
$Res call({
 ProductEntity product
});




}
/// @nodoc
class _$CartItemAddedCopyWithImpl<$Res>
    implements $CartItemAddedCopyWith<$Res> {
  _$CartItemAddedCopyWithImpl(this._self, this._then);

  final CartItemAdded _self;
  final $Res Function(CartItemAdded) _then;

/// Create a copy of CartEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? product = null,}) {
  return _then(CartItemAdded(
null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as ProductEntity,
  ));
}


}

/// @nodoc


class CartQtyChanged implements CartEvent {
  const CartQtyChanged(this.productId, this.qty);
  

 final  int productId;
 final  int qty;

/// Create a copy of CartEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartQtyChangedCopyWith<CartQtyChanged> get copyWith => _$CartQtyChangedCopyWithImpl<CartQtyChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartQtyChanged&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.qty, qty) || other.qty == qty));
}


@override
int get hashCode => Object.hash(runtimeType,productId,qty);

@override
String toString() {
  return 'CartEvent.qtyChanged(productId: $productId, qty: $qty)';
}


}

/// @nodoc
abstract mixin class $CartQtyChangedCopyWith<$Res> implements $CartEventCopyWith<$Res> {
  factory $CartQtyChangedCopyWith(CartQtyChanged value, $Res Function(CartQtyChanged) _then) = _$CartQtyChangedCopyWithImpl;
@useResult
$Res call({
 int productId, int qty
});




}
/// @nodoc
class _$CartQtyChangedCopyWithImpl<$Res>
    implements $CartQtyChangedCopyWith<$Res> {
  _$CartQtyChangedCopyWithImpl(this._self, this._then);

  final CartQtyChanged _self;
  final $Res Function(CartQtyChanged) _then;

/// Create a copy of CartEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? qty = null,}) {
  return _then(CartQtyChanged(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class CartItemRemoved implements CartEvent {
  const CartItemRemoved(this.productId);
  

 final  int productId;

/// Create a copy of CartEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartItemRemovedCopyWith<CartItemRemoved> get copyWith => _$CartItemRemovedCopyWithImpl<CartItemRemoved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartItemRemoved&&(identical(other.productId, productId) || other.productId == productId));
}


@override
int get hashCode => Object.hash(runtimeType,productId);

@override
String toString() {
  return 'CartEvent.itemRemoved(productId: $productId)';
}


}

/// @nodoc
abstract mixin class $CartItemRemovedCopyWith<$Res> implements $CartEventCopyWith<$Res> {
  factory $CartItemRemovedCopyWith(CartItemRemoved value, $Res Function(CartItemRemoved) _then) = _$CartItemRemovedCopyWithImpl;
@useResult
$Res call({
 int productId
});




}
/// @nodoc
class _$CartItemRemovedCopyWithImpl<$Res>
    implements $CartItemRemovedCopyWith<$Res> {
  _$CartItemRemovedCopyWithImpl(this._self, this._then);

  final CartItemRemoved _self;
  final $Res Function(CartItemRemoved) _then;

/// Create a copy of CartEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,}) {
  return _then(CartItemRemoved(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class CartCleared implements CartEvent {
  const CartCleared();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartCleared);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CartEvent.cleared()';
}


}




/// @nodoc


class CartPaymentChanged implements CartEvent {
  const CartPaymentChanged(this.amount);
  

 final  int amount;

/// Create a copy of CartEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartPaymentChangedCopyWith<CartPaymentChanged> get copyWith => _$CartPaymentChangedCopyWithImpl<CartPaymentChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartPaymentChanged&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,amount);

@override
String toString() {
  return 'CartEvent.paymentChanged(amount: $amount)';
}


}

/// @nodoc
abstract mixin class $CartPaymentChangedCopyWith<$Res> implements $CartEventCopyWith<$Res> {
  factory $CartPaymentChangedCopyWith(CartPaymentChanged value, $Res Function(CartPaymentChanged) _then) = _$CartPaymentChangedCopyWithImpl;
@useResult
$Res call({
 int amount
});




}
/// @nodoc
class _$CartPaymentChangedCopyWithImpl<$Res>
    implements $CartPaymentChangedCopyWith<$Res> {
  _$CartPaymentChangedCopyWithImpl(this._self, this._then);

  final CartPaymentChanged _self;
  final $Res Function(CartPaymentChanged) _then;

/// Create a copy of CartEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? amount = null,}) {
  return _then(CartPaymentChanged(
null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class CartCheckedOut implements CartEvent {
  const CartCheckedOut();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartCheckedOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CartEvent.checkedOut()';
}


}




// dart format on
