// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pin_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PinEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PinEvent()';
}


}

/// @nodoc
class $PinEventCopyWith<$Res>  {
$PinEventCopyWith(PinEvent _, $Res Function(PinEvent) __);
}


/// Adds pattern-matching-related methods to [PinEvent].
extension PinEventPatterns on PinEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PinStatusRequested value)?  statusRequested,TResult Function( PinCreated value)?  created,TResult Function( PinSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PinStatusRequested() when statusRequested != null:
return statusRequested(_that);case PinCreated() when created != null:
return created(_that);case PinSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PinStatusRequested value)  statusRequested,required TResult Function( PinCreated value)  created,required TResult Function( PinSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case PinStatusRequested():
return statusRequested(_that);case PinCreated():
return created(_that);case PinSubmitted():
return submitted(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PinStatusRequested value)?  statusRequested,TResult? Function( PinCreated value)?  created,TResult? Function( PinSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case PinStatusRequested() when statusRequested != null:
return statusRequested(_that);case PinCreated() when created != null:
return created(_that);case PinSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  statusRequested,TResult Function( String pin)?  created,TResult Function( String pin)?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PinStatusRequested() when statusRequested != null:
return statusRequested();case PinCreated() when created != null:
return created(_that.pin);case PinSubmitted() when submitted != null:
return submitted(_that.pin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  statusRequested,required TResult Function( String pin)  created,required TResult Function( String pin)  submitted,}) {final _that = this;
switch (_that) {
case PinStatusRequested():
return statusRequested();case PinCreated():
return created(_that.pin);case PinSubmitted():
return submitted(_that.pin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  statusRequested,TResult? Function( String pin)?  created,TResult? Function( String pin)?  submitted,}) {final _that = this;
switch (_that) {
case PinStatusRequested() when statusRequested != null:
return statusRequested();case PinCreated() when created != null:
return created(_that.pin);case PinSubmitted() when submitted != null:
return submitted(_that.pin);case _:
  return null;

}
}

}

/// @nodoc


class PinStatusRequested implements PinEvent {
  const PinStatusRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinStatusRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PinEvent.statusRequested()';
}


}




/// @nodoc


class PinCreated implements PinEvent {
  const PinCreated(this.pin);
  

 final  String pin;

/// Create a copy of PinEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PinCreatedCopyWith<PinCreated> get copyWith => _$PinCreatedCopyWithImpl<PinCreated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinCreated&&(identical(other.pin, pin) || other.pin == pin));
}


@override
int get hashCode => Object.hash(runtimeType,pin);

@override
String toString() {
  return 'PinEvent.created(pin: $pin)';
}


}

/// @nodoc
abstract mixin class $PinCreatedCopyWith<$Res> implements $PinEventCopyWith<$Res> {
  factory $PinCreatedCopyWith(PinCreated value, $Res Function(PinCreated) _then) = _$PinCreatedCopyWithImpl;
@useResult
$Res call({
 String pin
});




}
/// @nodoc
class _$PinCreatedCopyWithImpl<$Res>
    implements $PinCreatedCopyWith<$Res> {
  _$PinCreatedCopyWithImpl(this._self, this._then);

  final PinCreated _self;
  final $Res Function(PinCreated) _then;

/// Create a copy of PinEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pin = null,}) {
  return _then(PinCreated(
null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PinSubmitted implements PinEvent {
  const PinSubmitted(this.pin);
  

 final  String pin;

/// Create a copy of PinEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PinSubmittedCopyWith<PinSubmitted> get copyWith => _$PinSubmittedCopyWithImpl<PinSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinSubmitted&&(identical(other.pin, pin) || other.pin == pin));
}


@override
int get hashCode => Object.hash(runtimeType,pin);

@override
String toString() {
  return 'PinEvent.submitted(pin: $pin)';
}


}

/// @nodoc
abstract mixin class $PinSubmittedCopyWith<$Res> implements $PinEventCopyWith<$Res> {
  factory $PinSubmittedCopyWith(PinSubmitted value, $Res Function(PinSubmitted) _then) = _$PinSubmittedCopyWithImpl;
@useResult
$Res call({
 String pin
});




}
/// @nodoc
class _$PinSubmittedCopyWithImpl<$Res>
    implements $PinSubmittedCopyWith<$Res> {
  _$PinSubmittedCopyWithImpl(this._self, this._then);

  final PinSubmitted _self;
  final $Res Function(PinSubmitted) _then;

/// Create a copy of PinEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pin = null,}) {
  return _then(PinSubmitted(
null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
