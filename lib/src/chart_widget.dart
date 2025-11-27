// 1. 定义您的 ChartData Notifier
// 继承 Notifier 存储 ChartData 切片结果
import 'dart:typed_data';
import 'package:riverpod/riverpod.dart';
import 'package:vad/src/rust/api/audio_processor.dart';
import 'package:vad/src/rust/api/util.dart';

class AudioProcessorNotifier extends AsyncNotifier<AudioProcessor> {
  @override
  Future<AudioProcessor> build() async {
    return await AudioProcessor.newInstance(); 
  }
}

// 3. 定义最终的 Provider
// audioProcessorProvider 会暴露 AsyncValue<AudioProcessor>
final audioProcessorProvider = 
    AsyncNotifierProvider<AudioProcessorNotifier, AudioProcessor>(
      AudioProcessorNotifier.new,
    );

class WaveformNotifier extends Notifier<ChartData> {
  @override
  ChartData build() {
    return ChartData(index: Float64List(0), data: Float64List(0));
  }

  // 2. 异步方法 (调用 FFI)
  Future<void> fetchWaveform(String path, (int, int) indexRange) async {
    final asyncProcessor = ref.read(audioProcessorProvider);

    final processor = asyncProcessor.when(
      data: (processor) => processor,
      loading: () => throw Exception('AudioProcessor is still loading'),
      error: (error, stack) => throw Exception('Failed to load AudioProcessor: $error'),
    );

    final newWaveform = await processor.getAudioData(
        filePath: path,
        offset: (0.0, 0.0), // offset 需要是 (double, double)
        index: (BigInt.from(indexRange.$1), BigInt.from(indexRange.$2)), // index 需要是 (BigInt, BigInt)
    );

    state = newWaveform;
  }
}

// 4. 定义 Provider
final waveformProvider = NotifierProvider<WaveformNotifier, ChartData>(
  WaveformNotifier.new,
);
