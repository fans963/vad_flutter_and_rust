import 'package:signals/signals_flutter.dart';
import 'package:vad/src/rust/api/core/engine.dart';
import 'package:vad/src/rust/api/types/chart.dart';
import 'package:vad/src/rust/api/types/vad.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';

Future<List<VadParamDef>> loadVadParams() async {
  final engine = await audioProcessorEngine.engine();
  return await engine.getVadParams();
}

Future<void> setVadParam(String key, double value) async {
  final engine = await audioProcessorEngine.engine();
  await engine.setVadParam(key: key, value: value);
}

final vadAlgorithmNameSignal = signal("energy");
final vadAlgorithmsSignal = signal<List<String>>([]);
final vadParamsSignal = signal<List<VadParamDef>>([]);

/// VAD confidence chart points, keyed by file path.
final vadPointsSignal = signal<Map<String, List<Point>>>({});

/// Incremented when VAD results change, used by ChartWidget to trigger rebuild.
final vadVersionSignal = signal(0);

Future<void> refreshVadState() async {
  final engine = await audioProcessorEngine.engine();
  final names = await engine.listVadAlgorithms();
  vadAlgorithmsSignal.value = names;
  final current = await engine.getCurrentVadName();
  vadAlgorithmNameSignal.value = current;
  final params = await engine.getVadParams();
  vadParamsSignal.value = params;
}

Future<void> selectVadAlgorithm(String name) async {
  final engine = await audioProcessorEngine.engine();
  await engine.setVadAlgorithm(name: name);
  await refreshVadState();
}

Future<void> runVadOnFile(String filePath) async {
  final engine = await audioProcessorEngine.engine();
  final result = await engine.computeVad(filePath: filePath);

  final points = <Point>[];
  for (int i = 0; i < result.confidence.length; i++) {
    points.add(Point(
      x: (i * result.frameSize).toDouble(),
      y: result.confidence[i].toDouble(),
    ));
  }

  final updated = Map<String, List<Point>>.from(vadPointsSignal.value);
  updated[filePath] = points;
  vadPointsSignal.value = updated;
  vadVersionSignal.value++;
}

