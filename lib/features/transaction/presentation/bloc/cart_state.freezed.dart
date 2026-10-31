// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CartState {

 List<CartItem> get items; int get paymentAmount; CartStatus get status; String get errorMessage;/// Id transaksi yang baru tersimpan — dipakai layar untuk pindah ke struk.
 int? get lastTransactionId;
/// Create a copy of CartState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartStateCopyWith<CartState> get copyWith => _$CartStateCopyWithImpl<CartState>(this as CartState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartState&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.paymentAmount, paymentAmount) || other.paymentAmount == paymentAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.lastTransactionId, lastTransactionId) || other.lastTransactionId == lastTransactionId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),paymentAmount,status,errorMessage,lastTransactionId);

@override
String toString() {
  return 'CartState(items: $items, paymentAmount: $paymentAmount, status: $status, errorMessage: $errorMessage, lastTransactionId: $lastTransactionId)';
}


}

/// @nodoc
abstract mixin class $CartStateCopyWith<$Res>  {
  factory $CartStateCopyWith(CartState value, $Res Function(CartState) _then) = _$CartStateCopyWithImpl;
@useResult
$Res call({
 List<CartItem> items, int paymentAmount, CartStatus status, String errorMessage, int? lastTransactionId
});




}
/// @nodoc
class _$CartStateCopyWithImpl<$Res>
    implements $CartStateCopyWith<$Res> {
  _$CartStateCopyWithImpl(this._self, this._then);

  final CartState _self;
  final $Res Function(CartState) _then;

/// Create a copy of CartState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? paymentAmount = null,Object? status = null,Object? errorMessage = null,Object? lastTransactionId = freezed,}) {
  return _then(CartState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CartItem>,paymentAmount: null == paymentAmount ? _self.paymentAmount : paymentAmount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CartStatus,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,lastTransactionId: freezed == lastTransactionId ? _self.lastTransactionId : lastTransactionId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CartState].
extension CartStatePatterns on CartState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartState value)  $default,){
final _that = this;
switch (_that) {
case _CartState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartState value)?  $default,){
final _that = this;
switch (_that) {
case _CartState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CartItem> items,  int paymentAmount,  CartStatus status,  String errorMessage,  int? lastTransactionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartState() when $default != null:
return $default(_that.items,_that.paymentAmount,_that.status,_that.errorMessage,_that.lastTransactionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CartItem> items,  int paymentAmount,  CartStatus status,  String errorMessage,  int? lastTransactionId)  $default,) {final _that = this;
switch (_that) {
case _CartState():
return $default(_that.items,_that.paymentAmount,_that.status,_that.errorMessage,_that.lastTransactionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CartItem> items,  int paymentAmount,  CartStatus status,  String errorMessage,  int? lastTransactionId)?  $default,) {final _that = this;
switch (_that) {
case _CartState() when $default != null:
return $default(_that.items,_that.paymentAmount,_that.status,_that.errorMessage,_that.lastTransactionId);case _:
  return null;

}
}

}

/// @nodoc


class _CartState extends CartState {
  const _CartState({ List<CartItem> items = const [], this.paymentAmount = 0, this.status = CartStatus.editing, this.errorMessage = '', this.lastTransactionId}): _items = items,super._();
  

 final  List<CartItem> _items;
@override@JsonKey() List<CartItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int paymentAmount;
@override@JsonKey() final  CartStatus status;
@override@JsonKey() final  String errorMessage;
/// Id transaksi yang baru tersimpan — dipakai layar untuk pindah ke struk.
@override final  int? lastTransactionId;

/// Create a copy of CartState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartStateCopyWith<_CartState> get copyWith => __$CartStateCopyWithImpl<_CartState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartState&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.paymentAmount, paymentAmount) || other.paymentAmount == paymentAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.lastTransactionId, lastTransactionId) || other.lastTransactionId == lastTransactionId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),paymentAmount,status,errorMessage,lastTransactionId);

@override
String toString() {
  return 'CartState(items: $items, paymentAmount: $paymentAmount, status: $status, errorMessage: $errorMessage, lastTransactionId: $lastTransactionId)';
}


}

/// @nodoc
abstract mixin class _$CartStateCopyWith<$Res> implements $CartStateCopyWith<$Res> {
  factory _$CartStateCopyWith(_CartState value, $Res Function(_CartState) _then) = __$CartStateCopyWithImpl;
@override @useResult
$Res call({
 List<CartItem> items, int paymentAmount, CartStatus status, String errorMessage, int? lastTransactionId
});




}
/// @nodoc
class __$CartStateCopyWithImpl<$Res>
    implements _$CartStateCopyWith<$Res> {
  __$CartStateCopyWithImpl(this._self, this._then);

  final _CartState _self;
  final $Res Function(_CartState) _then;

/// Create a copy of CartState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? paymentAmount = null,Object? status = null,Object? errorMessage = null,Object? lastTransactionId = freezed,}) {
  return _then(_CartState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CartItem>,paymentAmount: null == paymentAmount ? _self.paymentAmount : paymentAmount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CartStatus,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,lastTransactionId: freezed == lastTransactionId ? _self.lastTransactionId : lastTransactionId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
