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
  await engine.removeChart(filePath: filePath, dataType: DataType.vad);
  await engine.addChart(filePath: filePath, dataType: DataType.vad);
}

