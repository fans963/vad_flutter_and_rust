import 'package:riverpod/legacy.dart';

typedef ChartControlParameter = ({
  double maxIndex,
  double minX,
  double maxX,
  double minY,
  double maxY,
});

class ChartControlProvider extends StateNotifier<ChartControlParameter> {
  ChartControlProvider() : super((maxIndex: 0, minX: 0, maxX: 10000, minY: -0.5, maxY: 0.5));
  void setControlParameter(ChartControlParameter parameter) {
    state = parameter;
  }
}

final chartControlProvider =
    StateNotifierProvider<ChartControlProvider, ChartControlParameter>(
      (ref) => ChartControlProvider(),
    );
