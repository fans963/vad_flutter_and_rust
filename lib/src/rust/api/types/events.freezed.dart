// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'events.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChartEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChartEvent()';
}


}

/// @nodoc
class $ChartEventCopyWith<$Res>  {
$ChartEventCopyWith(ChartEvent _, $Res Function(ChartEvent) __);
}


/// Adds pattern-matching-related methods to [ChartEvent].
extension ChartEventPatterns on ChartEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChartEvent_AddChart value)?  addChart,TResult Function( ChartEvent_RemoveChart value)?  removeChart,TResult Function( ChartEvent_RemoveAllCharts value)?  removeAllCharts,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChartEvent_AddChart() when addChart != null:
return addChart(_that);case ChartEvent_RemoveChart() when removeChart != null:
return removeChart(_that);case ChartEvent_RemoveAllCharts() when removeAllCharts != null:
return removeAllCharts(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChartEvent_AddChart value)  addChart,required TResult Function( ChartEvent_RemoveChart value)  removeChart,required TResult Function( ChartEvent_RemoveAllCharts value)  removeAllCharts,}){
final _that = this;
switch (_that) {
case ChartEvent_AddChart():
return addChart(_that);case ChartEvent_RemoveChart():
return removeChart(_that);case ChartEvent_RemoveAllCharts():
return removeAllCharts(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChartEvent_AddChart value)?  addChart,TResult? Function( ChartEvent_RemoveChart value)?  removeChart,TResult? Function( ChartEvent_RemoveAllCharts value)?  removeAllCharts,}){
final _that = this;
switch (_that) {
case ChartEvent_AddChart() when addChart != null:
return addChart(_that);case ChartEvent_RemoveChart() when removeChart != null:
return removeChart(_that);case ChartEvent_RemoveAllCharts() when removeAllCharts != null:
return removeAllCharts(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String key,  CommunicatorChart chart)?  addChart,TResult Function( String key,  DataType dataType)?  removeChart,TResult Function()?  removeAllCharts,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChartEvent_AddChart() when addChart != null:
return addChart(_that.key,_that.chart);case ChartEvent_RemoveChart() when removeChart != null:
return removeChart(_that.key,_that.dataType);case ChartEvent_RemoveAllCharts() when removeAllCharts != null:
return removeAllCharts();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String key,  CommunicatorChart chart)  addChart,required TResult Function( String key,  DataType dataType)  removeChart,required TResult Function()  removeAllCharts,}) {final _that = this;
switch (_that) {
case ChartEvent_AddChart():
return addChart(_that.key,_that.chart);case ChartEvent_RemoveChart():
return removeChart(_that.key,_that.dataType);case ChartEvent_RemoveAllCharts():
return removeAllCharts();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String key,  CommunicatorChart chart)?  addChart,TResult? Function( String key,  DataType dataType)?  removeChart,TResult? Function()?  removeAllCharts,}) {final _that = this;
switch (_that) {
case ChartEvent_AddChart() when addChart != null:
return addChart(_that.key,_that.chart);case ChartEvent_RemoveChart() when removeChart != null:
return removeChart(_that.key,_that.dataType);case ChartEvent_RemoveAllCharts() when removeAllCharts != null:
return removeAllCharts();case _:
  return null;

}
}

}

/// @nodoc


class ChartEvent_AddChart extends ChartEvent {
  const ChartEvent_AddChart({required this.key, required this.chart}): super._();
  

 final  String key;
 final  CommunicatorChart chart;

/// Create a copy of ChartEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartEvent_AddChartCopyWith<ChartEvent_AddChart> get copyWith => _$ChartEvent_AddChartCopyWithImpl<ChartEvent_AddChart>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartEvent_AddChart&&(identical(other.key, key) || other.key == key)&&(identical(other.chart, chart) || other.chart == chart));
}


@override
int get hashCode => Object.hash(runtimeType,key,chart);

@override
String toString() {
  return 'ChartEvent.addChart(key: $key, chart: $chart)';
}


}

/// @nodoc
abstract mixin class $ChartEvent_AddChartCopyWith<$Res> implements $ChartEventCopyWith<$Res> {
  factory $ChartEvent_AddChartCopyWith(ChartEvent_AddChart value, $Res Function(ChartEvent_AddChart) _then) = _$ChartEvent_AddChartCopyWithImpl;
@useResult
$Res call({
 String key, CommunicatorChart chart
});




}
/// @nodoc
class _$ChartEvent_AddChartCopyWithImpl<$Res>
    implements $ChartEvent_AddChartCopyWith<$Res> {
  _$ChartEvent_AddChartCopyWithImpl(this._self, this._then);

  final ChartEvent_AddChart _self;
  final $Res Function(ChartEvent_AddChart) _then;

/// Create a copy of ChartEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? key = null,Object? chart = null,}) {
  return _then(ChartEvent_AddChart(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,chart: null == chart ? _self.chart : chart // ignore: cast_nullable_to_non_nullable
as CommunicatorChart,
  ));
}


}

/// @nodoc


class ChartEvent_RemoveChart extends ChartEvent {
  const ChartEvent_RemoveChart({required this.key, required this.dataType}): super._();
  

 final  String key;
 final  DataType dataType;

/// Create a copy of ChartEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartEvent_RemoveChartCopyWith<ChartEvent_RemoveChart> get copyWith => _$ChartEvent_RemoveChartCopyWithImpl<ChartEvent_RemoveChart>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartEvent_RemoveChart&&(identical(other.key, key) || other.key == key)&&(identical(other.dataType, dataType) || other.dataType == dataType));
}


@override
int get hashCode => Object.hash(runtimeType,key,dataType);

@override
String toString() {
  return 'ChartEvent.removeChart(key: $key, dataType: $dataType)';
}


}

/// @nodoc
abstract mixin class $ChartEvent_RemoveChartCopyWith<$Res> implements $ChartEventCopyWith<$Res> {
  factory $ChartEvent_RemoveChartCopyWith(ChartEvent_RemoveChart value, $Res Function(ChartEvent_RemoveChart) _then) = _$ChartEvent_RemoveChartCopyWithImpl;
@useResult
$Res call({
 String key, DataType dataType
});




}
/// @nodoc
class _$ChartEvent_RemoveChartCopyWithImpl<$Res>
    implements $ChartEvent_RemoveChartCopyWith<$Res> {
  _$ChartEvent_RemoveChartCopyWithImpl(this._self, this._then);

  final ChartEvent_RemoveChart _self;
  final $Res Function(ChartEvent_RemoveChart) _then;

/// Create a copy of ChartEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? key = null,Object? dataType = null,}) {
  return _then(ChartEvent_RemoveChart(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,dataType: null == dataType ? _self.dataType : dataType // ignore: cast_nullable_to_non_nullable
as DataType,
  ));
}


}

/// @nodoc


class ChartEvent_RemoveAllCharts extends ChartEvent {
  const ChartEvent_RemoveAllCharts(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartEvent_RemoveAllCharts);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChartEvent.removeAllCharts()';
}


}




// dart format on
