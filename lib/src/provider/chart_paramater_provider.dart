import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:vad/src/provider/audio_process_providr.dart';
import 'package:vad/src/rust/api/audio_processor.dart';

enum ChartDataType { Waveform, AmplitudeSpectrum }

typedef ChartDataParameter = ({
  String filePath,
  bool visible,
  (double, double) offset,
  (BigInt, BigInt) index,
  ChartDataType dataType,
  double downSampleFactor,
  Color ?color,
});

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

// New provider for chart data
final chartDataProvider = FutureProvider<List<LineChartBarData>>((ref) async {
  final activeCharts = ref.watch(chartParameterProvider);
  final audioProcessorAsync = ref.watch(audioProcessorProvider);

  if (activeCharts.isEmpty) return [];

  final processor = audioProcessorAsync.maybeWhen(
    data: (p) => p,
    orElse: () => throw Exception('Audio processor not ready'),
  );

  final lineBars = <LineChartBarData>[];

  for (final chart in activeCharts) {
    debugPrint('Rendering chart for file: ${chart.filePath}');
    final chartData = await processor.getDownSampledData(
      filePath: chart.filePath,
      offset: chart.offset,
      index: chart.index,
      downSampleFactor: chart.downSampleFactor,
    );

    lineBars.add(
      LineChartBarData(
        dotData: const FlDotData(show: false),
        spots: List.generate(
          chartData.index.length,
          (i) => FlSpot(chartData.index[i], chartData.data[i]),
        ),
        isCurved: false,
        color: chart.color ?? Colors.blue,
      ),
    );
  }

  return lineBars;
});
