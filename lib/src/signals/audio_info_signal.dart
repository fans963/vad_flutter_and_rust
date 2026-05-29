import 'package:signals/signals_flutter.dart';
import 'package:vad/src/rust/api/types/audio.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';

final audioInfoMapSignal = signal<Map<String, AudioInfo>>({});

Future<void> loadAudioInfo(String filePath) async {
  final engine = await audioProcessorEngine.engine();
  final info = await engine.getAudioInfo(filePath: filePath);
  final map = Map<String, AudioInfo>.from(audioInfoMapSignal.value);
  map[filePath] = info;
  audioInfoMapSignal.value = map;
}

Future<void> loadAllAudioInfo() async {
  final engine = await audioProcessorEngine.engine();
  final files = await engine.getLoadedFiles();
  final map = <String, AudioInfo>{};
  for (final path in files) {
    try {
      final info = await engine.getAudioInfo(filePath: path);
      map[path] = info;
    } catch (_) {}
  }
  audioInfoMapSignal.value = map;
}

String formatDuration(double secs) {
  final m = (secs ~/ 60).toString().padLeft(2, '0');
  final s = (secs % 60).toStringAsFixed(1).padLeft(4, '0');
  return '$m:$s';
}

String formatSampleCount(dynamic count) {
  final n = count is BigInt ? count.toInt() : count as int;
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1)}M';
  } else if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1)}K';
  }
  return n.toString();
}
