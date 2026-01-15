import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:riverpod/legacy.dart';
import 'package:vad/src/rust/api/types/chart.dart';

typedef ChartDataParameter = ({
  bool visible,
  (double, double) offset,
  DataType dataType,
  Color? color,
});

class ChartDataNotifier extends StateNotifier<HashMap<String,ChartDataParameter>> {
  ChartDataNotifier() : super(HashMap());

  List<ChartDataParameter> getChartParameters() {
    return state.values.toList();
  }

  void add(String key, ChartDataParameter parameter) {
    state[key] = parameter;
  }

  void delete(String key) {
    state.remove(key);
  }
}

final chartParameterProvider =
    StateNotifierProvider<ChartDataNotifier, HashMap<String,ChartDataParameter>>(
      (ref) => ChartDataNotifier(),
    );
