import 'package:signals/signals_flutter.dart';

typedef ChartControlParameter = ({
  double minX,
  double maxX,
  double minY,
  double maxY,
});

const _initialParams = (minX: 0.0, maxX: 1.0, minY: -1.0, maxY: 1.0);

final chartControlSignal = signal<ChartControlParameter>(_initialParams);

