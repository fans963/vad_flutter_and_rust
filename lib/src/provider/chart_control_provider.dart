import 'package:riverpod/riverpod.dart';

typedef ChartControlParameter = ({
  double minX,
  double maxX,
  double minY,
  double maxY,
});

class ChartControlProvider extends AsyncNotifier<ChartControlParameter> {
  @override
  Future<ChartControlParameter> build() async {
    return (minX: 0.0, maxX: 1.0, minY: -1.0, maxY: 1.0);
  }

  void setControlParameter(ChartControlParameter parameter) {
    state = AsyncValue.data(parameter);
  }
}

final chartControlProvider =
    AsyncNotifierProvider<ChartControlProvider, ChartControlParameter>(
      () => ChartControlProvider(),
    );
