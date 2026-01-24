import 'dart:typed_data';
import 'package:signals/signals_flutter.dart';
import 'package:vad/src/rust/api/core/engine.dart';
import 'package:vad/src/rust/api/types/config.dart';

class AudioProcessorController {
  late final _engineSignal = futureSignal(() async {
    return await createDefaultEngine(
      config: Config(frameSize: BigInt.from(512)),
    );
  });

  AsyncState<AudioProcessorEngine> get state => _engineSignal.value;

  Future<AudioProcessorEngine> engine() async {
    return await _engineSignal.future;
  }

  Future<void> addFile(String filePath, Uint8List fileData) async {
    try {
      final audioEngine = await engine();
      await audioEngine.add(filePath: filePath, audioData: fileData);
    } catch (e, st) {
      _engineSignal.setError(e, st);
      rethrow;
    }
  }
}

final audioProcessorEngine = AudioProcessorController();
