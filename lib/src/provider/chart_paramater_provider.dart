import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:vad/src/provider/audio_process_providr.dart';
import 'package:vad/src/rust/api/audio_processor.dart';
import 'package:vad/src/rust/api/util.dart';

typedef ChartDataParameter = ({
  String filePath,
  bool visible,
  (double, double) offset,
  (BigInt, BigInt) index,
  DataType dataType,
  int targetWidth,
  Color? color,
});

typedef ChartSeriesData = ({ChartData chartData, Color color});

class ChartDataNotifier extends StateNotifier<List<ChartDataParameter>> {
  ChartDataNotifier() : super([]);

  List<ChartDataParameter> getChartParameters() {
    return state;
  }

  void add(ChartDataParameter parameter) {
    state = [...state, parameter];
  }

  void delete(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }
}

final chartParameterProvider =
    StateNotifierProvider<ChartDataNotifier, List<ChartDataParameter>>(
      (ref) => ChartDataNotifier(),
    );

final chartDataProvider = FutureProvider<List<ChartSeriesData>>((ref) async {
  final activeCharts = ref.watch(chartParameterProvider);
  final audioProcessorAsync = ref.watch(audioProcessorProvider);

  if (activeCharts.isEmpty) return [];

  final processor = audioProcessorAsync.maybeWhen(
    data: (p) => p,
    orElse: () => throw Exception('Audio processor not ready'),
  );

  final seriesData = <ChartSeriesData>[];

  for (final chart in activeCharts) {
    debugPrint('Rendering chart for file: ${chart.filePath}');
    final chartData = await processor.getDownSampledData(
      filePath: chart.filePath,
      dataType: DataType.audio,
      offset: chart.offset,
      index: chart.index,
      targetWidth: BigInt.from(chart.targetWidth),
    );

    seriesData.add((chartData: chartData, color: chart.color ?? Colors.blue));
  }

  return seriesData;
});
