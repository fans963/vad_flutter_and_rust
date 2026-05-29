import 'package:flutter/foundation.dart';
import 'package:signals/signals_flutter.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';

final isPlayingSignal = signal(false);
final playbackPositionSignal = signal(Duration.zero);
final playbackDurationSignal = signal(Duration.zero);
final playbackFractionSignal = signal(0.0);
final playbackChartPositionSignal = signal(0.0);

/// Tracks which audio file is currently loaded in the player.
/// Null means no audio is loaded.
final loadedFilePathSignal = signal<String?>(null);

/// Error message from the last playback attempt, if any.
final playbackErrorSignal = signal<String?>(null);

void updatePlaybackState(
  bool isPlaying,
  double position,
  double duration,
  double chartPosition,
) {
  isPlayingSignal.value = isPlaying;
  playbackPositionSignal.value = Duration(milliseconds: (position * 1000).round());
  playbackDurationSignal.value = Duration(milliseconds: (duration * 1000).round());
  if (duration > 0.0) {
    playbackFractionSignal.value = position / duration;
  }
  playbackChartPositionSignal.value = chartPosition;
}

Future<void> playAudio(String filePath, {double startFraction = 0.0}) async {
  final engine = await audioProcessorEngine.engine();
  loadedFilePathSignal.value = filePath;
  playbackErrorSignal.value = null;
  try {
    await engine.playAudio(filePath: filePath, startFraction: startFraction);
  } catch (e) {
    playbackErrorSignal.value = e.toString();
    debugPrint('playAudio error: $e');
  }
}

Future<void> togglePlayPause() async {
  final engine = await audioProcessorEngine.engine();
  if (isPlayingSignal.value) {
    await engine.pauseAudio();
  } else {
    playbackErrorSignal.value = null;
    try {
      await engine.resumeAudio();
    } catch (e) {
      playbackErrorSignal.value = e.toString();
      debugPrint('resumeAudio error: $e');
    }
  }
}

Future<void> stopAudio() async {
  final engine = await audioProcessorEngine.engine();
  await engine.stopAudio();
  isPlayingSignal.value = false;
  playbackPositionSignal.value = Duration.zero;
  playbackFractionSignal.value = 0.0;
  playbackChartPositionSignal.value = 0.0;
}

Future<void> seekTo(double fraction) async {
  final engine = await audioProcessorEngine.engine();
  await engine.seekAudio(fraction: fraction);
}

Future<void> setPlaybackSpeed(double multiplier) async {
  final engine = await audioProcessorEngine.engine();
  await engine.setPlaybackSpeed(multiplier: multiplier);
}
