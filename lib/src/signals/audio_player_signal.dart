import 'package:signals/signals_flutter.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';

final isPlayingSignal = signal(false);
final playbackPositionSignal = signal(Duration.zero);
final playbackDurationSignal = signal(Duration.zero);
final playbackFractionSignal = signal(0.0);

void updatePlaybackState(bool isPlaying, double position, double duration) {
  isPlayingSignal.value = isPlaying;
  playbackPositionSignal.value = Duration(milliseconds: (position * 1000).round());
  playbackDurationSignal.value = Duration(milliseconds: (duration * 1000).round());
  if (duration > 0.0) {
    playbackFractionSignal.value = position / duration;
  }
}

Future<void> playAudio(String filePath, {double startFraction = 0.0}) async {
  final engine = await audioProcessorEngine.engine();
  await engine.playAudio(filePath: filePath, startFraction: startFraction);
}

Future<void> togglePlayPause() async {
  final engine = await audioProcessorEngine.engine();
  if (isPlayingSignal.value) {
    await engine.pauseAudio();
  } else {
    await engine.playAudio(filePath: '', startFraction: playbackFractionSignal.value);
  }
}

Future<void> stopAudio() async {
  final engine = await audioProcessorEngine.engine();
  await engine.stopAudio();
  isPlayingSignal.value = false;
  playbackPositionSignal.value = Duration.zero;
  playbackFractionSignal.value = 0.0;
}

Future<void> seekTo(double fraction) async {
  final engine = await audioProcessorEngine.engine();
  await engine.seekAudio(fraction: fraction);
}
