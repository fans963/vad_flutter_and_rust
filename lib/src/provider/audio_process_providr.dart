import 'package:riverpod/riverpod.dart';
import 'package:vad/src/rust/api/audio_processor.dart';

class AudioProcessorNotifier extends AsyncNotifier<AudioProcessor> {
  @override
  Future<AudioProcessor> build() async {
    return AudioProcessor.newInstance();
  }
}

final audioProcessorProvider =
    AsyncNotifierProvider<AudioProcessorNotifier, AudioProcessor>(
      AudioProcessorNotifier.new,
    );
