import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';
import 'package:vad/src/rust/api/core/engine.dart';
import 'package:vad/src/rust/api/types/config.dart';

class AudioProcessorNotifier extends AsyncNotifier<AudioProcessorEngine> {
  @override
  Future<AudioProcessorEngine> build() async {
    return createDefaultEngine(config: Config(frameSize: BigInt.from(512)));
  }

  Future<void> addFile(String filePath, Uint8List fileData) async {
    state = await AsyncValue.guard(() async {
      final processor = await future;
      await processor.add(filePath: filePath, audioData: fileData);
      return processor;
    });
  }
}

final audioProcessorProvider =
    AsyncNotifierProvider<AudioProcessorNotifier, AudioProcessorEngine>(
      AudioProcessorNotifier.new,
    );
