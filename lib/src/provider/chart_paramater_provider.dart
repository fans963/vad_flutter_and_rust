import 'package:riverpod/legacy.dart';

enum ChartDataType { Waveform, AmplitudeSpectrum }

typedef ChartDataParameter = ({
  String filePath,
  bool visible,
  (double, double) offset,
  (BigInt, BigInt) index,
  ChartDataType dataType,
  double? downSampleFactor,
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
