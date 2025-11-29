import 'dart:typed_data';

import 'package:riverpod/riverpod.dart';
import 'package:vad/src/rust/api/audio_processor.dart';

class AudioProcessorNotifier extends AsyncNotifier<AudioProcessor> {
  @override
  Future<AudioProcessor> build() async {
    return AudioProcessor.newInstance();
  }

  Future<void> addFile(String filePath,Uint8List fileData) async {
    state = await AsyncValue.guard(() async {
      final processor = await state.value!;
      await processor.add(filePath: filePath, fileData: fileData);
      return processor;
    });
  }
}

final audioProcessorProvider =
    AsyncNotifierProvider<AudioProcessorNotifier, AudioProcessor>(
      AudioProcessorNotifier.new,
    );
