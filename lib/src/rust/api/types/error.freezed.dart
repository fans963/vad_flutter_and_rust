// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppError {

 String get field0;
/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppErrorCopyWith<AppError> get copyWith => _$AppErrorCopyWithImpl<AppError>(this as AppError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppError&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'AppError(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $AppErrorCopyWith<$Res>  {
  factory $AppErrorCopyWith(AppError value, $Res Function(AppError) _then) = _$AppErrorCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$AppErrorCopyWithImpl<$Res>
    implements $AppErrorCopyWith<$Res> {
  _$AppErrorCopyWithImpl(this._self, this._then);

  final AppError _self;
  final $Res Function(AppError) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field0 = null,}) {
  return _then(_self.copyWith(
field0: null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppError].
extension AppErrorPatterns on AppError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AppError_Io value)?  io,TResult Function( AppError_Format value)?  format,TResult Function( AppError_Decode value)?  decode,TResult Function( AppError_Storage value)?  storage,TResult Function( AppError_Cache value)?  cache,TResult Function( AppError_NotFound value)?  notFound,TResult Function( AppError_Generic value)?  generic,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AppError_Io() when io != null:
return io(_that);case AppError_Format() when format != null:
return format(_that);case AppError_Decode() when decode != null:
return decode(_that);case AppError_Storage() when storage != null:
return storage(_that);case AppError_Cache() when cache != null:
return cache(_that);case AppError_NotFound() when notFound != null:
return notFound(_that);case AppError_Generic() when generic != null:
return generic(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AppError_Io value)  io,required TResult Function( AppError_Format value)  format,required TResult Function( AppError_Decode value)  decode,required TResult Function( AppError_Storage value)  storage,required TResult Function( AppError_Cache value)  cache,required TResult Function( AppError_NotFound value)  notFound,required TResult Function( AppError_Generic value)  generic,}){
final _that = this;
switch (_that) {
case AppError_Io():
return io(_that);case AppError_Format():
return format(_that);case AppError_Decode():
return decode(_that);case AppError_Storage():
return storage(_that);case AppError_Cache():
return cache(_that);case AppError_NotFound():
return notFound(_that);case AppError_Generic():
return generic(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AppError_Io value)?  io,TResult? Function( AppError_Format value)?  format,TResult? Function( AppError_Decode value)?  decode,TResult? Function( AppError_Storage value)?  storage,TResult? Function( AppError_Cache value)?  cache,TResult? Function( AppError_NotFound value)?  notFound,TResult? Function( AppError_Generic value)?  generic,}){
final _that = this;
switch (_that) {
case AppError_Io() when io != null:
return io(_that);case AppError_Format() when format != null:
return format(_that);case AppError_Decode() when decode != null:
return decode(_that);case AppError_Storage() when storage != null:
return storage(_that);case AppError_Cache() when cache != null:
return cache(_that);case AppError_NotFound() when notFound != null:
return notFound(_that);case AppError_Generic() when generic != null:
return generic(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field0)?  io,TResult Function( String field0)?  format,TResult Function( String field0)?  decode,TResult Function( String field0)?  storage,TResult Function( String field0)?  cache,TResult Function( String field0)?  notFound,TResult Function( String field0)?  generic,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AppError_Io() when io != null:
return io(_that.field0);case AppError_Format() when format != null:
return format(_that.field0);case AppError_Decode() when decode != null:
return decode(_that.field0);case AppError_Storage() when storage != null:
return storage(_that.field0);case AppError_Cache() when cache != null:
return cache(_that.field0);case AppError_NotFound() when notFound != null:
return notFound(_that.field0);case AppError_Generic() when generic != null:
return generic(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field0)  io,required TResult Function( String field0)  format,required TResult Function( String field0)  decode,required TResult Function( String field0)  storage,required TResult Function( String field0)  cache,required TResult Function( String field0)  notFound,required TResult Function( String field0)  generic,}) {final _that = this;
switch (_that) {
case AppError_Io():
return io(_that.field0);case AppError_Format():
return format(_that.field0);case AppError_Decode():
return decode(_that.field0);case AppError_Storage():
return storage(_that.field0);case AppError_Cache():
return cache(_that.field0);case AppError_NotFound():
return notFound(_that.field0);case AppError_Generic():
return generic(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field0)?  io,TResult? Function( String field0)?  format,TResult? Function( String field0)?  decode,TResult? Function( String field0)?  storage,TResult? Function( String field0)?  cache,TResult? Function( String field0)?  notFound,TResult? Function( String field0)?  generic,}) {final _that = this;
switch (_that) {
case AppError_Io() when io != null:
return io(_that.field0);case AppError_Format() when format != null:
return format(_that.field0);case AppError_Decode() when decode != null:
return decode(_that.field0);case AppError_Storage() when storage != null:
return storage(_that.field0);case AppError_Cache() when cache != null:
return cache(_that.field0);case AppError_NotFound() when notFound != null:
return notFound(_that.field0);case AppError_Generic() when generic != null:
return generic(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class AppError_Io extends AppError {
  const AppError_Io(this.field0): super._();
  

@override final  String field0;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppError_IoCopyWith<AppError_Io> get copyWith => _$AppError_IoCopyWithImpl<AppError_Io>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppError_Io&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'AppError.io(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $AppError_IoCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $AppError_IoCopyWith(AppError_Io value, $Res Function(AppError_Io) _then) = _$AppError_IoCopyWithImpl;
@override @useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$AppError_IoCopyWithImpl<$Res>
    implements $AppError_IoCopyWith<$Res> {
  _$AppError_IoCopyWithImpl(this._self, this._then);

  final AppError_Io _self;
  final $Res Function(AppError_Io) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(AppError_Io(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AppError_Format extends AppError {
  const AppError_Format(this.field0): super._();
  

@override final  String field0;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppError_FormatCopyWith<AppError_Format> get copyWith => _$AppError_FormatCopyWithImpl<AppError_Format>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppError_Format&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'AppError.format(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $AppError_FormatCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $AppError_FormatCopyWith(AppError_Format value, $Res Function(AppError_Format) _then) = _$AppError_FormatCopyWithImpl;
@override @useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$AppError_FormatCopyWithImpl<$Res>
    implements $AppError_FormatCopyWith<$Res> {
  _$AppError_FormatCopyWithImpl(this._self, this._then);

  final AppError_Format _self;
  final $Res Function(AppError_Format) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(AppError_Format(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AppError_Decode extends AppError {
  const AppError_Decode(this.field0): super._();
  

@override final  String field0;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppError_DecodeCopyWith<AppError_Decode> get copyWith => _$AppError_DecodeCopyWithImpl<AppError_Decode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppError_Decode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'AppError.decode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $AppError_DecodeCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $AppError_DecodeCopyWith(AppError_Decode value, $Res Function(AppError_Decode) _then) = _$AppError_DecodeCopyWithImpl;
@override @useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$AppError_DecodeCopyWithImpl<$Res>
    implements $AppError_DecodeCopyWith<$Res> {
  _$AppError_DecodeCopyWithImpl(this._self, this._then);

  final AppError_Decode _self;
  final $Res Function(AppError_Decode) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(AppError_Decode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AppError_Storage extends AppError {
  const AppError_Storage(this.field0): super._();
  

@override final  String field0;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppError_StorageCopyWith<AppError_Storage> get copyWith => _$AppError_StorageCopyWithImpl<AppError_Storage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppError_Storage&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'AppError.storage(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $AppError_StorageCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $AppError_StorageCopyWith(AppError_Storage value, $Res Function(AppError_Storage) _then) = _$AppError_StorageCopyWithImpl;
@override @useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$AppError_StorageCopyWithImpl<$Res>
    implements $AppError_StorageCopyWith<$Res> {
  _$AppError_StorageCopyWithImpl(this._self, this._then);

  final AppError_Storage _self;
  final $Res Function(AppError_Storage) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(AppError_Storage(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AppError_Cache extends AppError {
  const AppError_Cache(this.field0): super._();
  

@override final  String field0;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppError_CacheCopyWith<AppError_Cache> get copyWith => _$AppError_CacheCopyWithImpl<AppError_Cache>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppError_Cache&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'AppError.cache(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $AppError_CacheCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $AppError_CacheCopyWith(AppError_Cache value, $Res Function(AppError_Cache) _then) = _$AppError_CacheCopyWithImpl;
@override @useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$AppError_CacheCopyWithImpl<$Res>
    implements $AppError_CacheCopyWith<$Res> {
  _$AppError_CacheCopyWithImpl(this._self, this._then);

  final AppError_Cache _self;
  final $Res Function(AppError_Cache) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(AppError_Cache(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AppError_NotFound extends AppError {
  const AppError_NotFound(this.field0): super._();
  

@override final  String field0;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppError_NotFoundCopyWith<AppError_NotFound> get copyWith => _$AppError_NotFoundCopyWithImpl<AppError_NotFound>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppError_NotFound&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'AppError.notFound(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $AppError_NotFoundCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $AppError_NotFoundCopyWith(AppError_NotFound value, $Res Function(AppError_NotFound) _then) = _$AppError_NotFoundCopyWithImpl;
@override @useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$AppError_NotFoundCopyWithImpl<$Res>
    implements $AppError_NotFoundCopyWith<$Res> {
  _$AppError_NotFoundCopyWithImpl(this._self, this._then);

  final AppError_NotFound _self;
  final $Res Function(AppError_NotFound) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(AppError_NotFound(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AppError_Generic extends AppError {
  const AppError_Generic(this.field0): super._();
  

@override final  String field0;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppError_GenericCopyWith<AppError_Generic> get copyWith => _$AppError_GenericCopyWithImpl<AppError_Generic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppError_Generic&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'AppError.generic(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $AppError_GenericCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $AppError_GenericCopyWith(AppError_Generic value, $Res Function(AppError_Generic) _then) = _$AppError_GenericCopyWithImpl;
@override @useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$AppError_GenericCopyWithImpl<$Res>
    implements $AppError_GenericCopyWith<$Res> {
  _$AppError_GenericCopyWithImpl(this._self, this._then);

  final AppError_Generic _self;
  final $Res Function(AppError_Generic) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(AppError_Generic(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
