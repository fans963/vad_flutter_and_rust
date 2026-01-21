import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:vad/src/rust/api/types/chart.dart';

typedef ChartDataParameter = ({
  bool visible,
  (double, double) offset,
  DataType dataType,
  Color? color,
});

class ChartDataNotifier
    extends AsyncNotifier<HashMap<String, ChartDataParameter>> {
  @override
  Future<HashMap<String, ChartDataParameter>> build() async {
    return HashMap<String, ChartDataParameter>();
  }

  List<ChartDataParameter> getChartParameters() {
    final currentState = state.value;
    if (currentState == null) return [];
    return currentState.values.toList();
  }

  void add(String key, ChartDataParameter parameter) {
    final currentState = state.value;
    if (currentState != null) {
      final newState = HashMap<String, ChartDataParameter>.from(currentState);
      newState[key] = parameter;
      state = AsyncValue.data(newState);
    }
  }

  void delete(String key) {
    final currentState = state.value;
    if (currentState != null) {
      final newState = HashMap<String, ChartDataParameter>.from(currentState);
      newState.remove(key);
      state = AsyncValue.data(newState);
    }
  }
}

final chartParameterProvider =
    AsyncNotifierProvider<
      ChartDataNotifier,
      HashMap<String, ChartDataParameter>
    >(() => ChartDataNotifier(),
    );
