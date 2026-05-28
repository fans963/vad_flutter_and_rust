import 'package:signals/signals_flutter.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';

final isPlayingSignal = signal(false);
final playbackPositionSignal = signal(Duration.zero);
final playbackDurationSignal = signal(Duration.zero);
final playbackFractionSignal = signal(0.0);

/// Tracks which audio file is currently loaded in the player.
/// Null means no audio is loaded.
final loadedFilePathSignal = signal<String?>(null);

void updatePlaybackState(bool isPlaying, double position, double duration) {
  isPlayingSignal.value = isPlaying;
  playbackPositionSignal.value = Duration(milliseconds: (position * 1000).round());
  playbackDurationSignal.value = Duration(milliseconds: (duration * 1000).round());
  if (duration > 0.0) {
    playbackFractionSignal.value = position / duration;
  }
}

/// Play audio from a file. If the same file is already loaded, resumes from
/// `startFraction`. If a different file is loaded, loads the new file and plays.
Future<void> playAudio(String filePath, {double startFraction = 0.0}) async {
  final engine = await audioProcessorEngine.engine();
  loadedFilePathSignal.value = filePath;
  await engine.playAudio(filePath: filePath, startFraction: startFraction);
}

/// Toggle between play and pause. Resumes from the current position.
Future<void> togglePlayPause() async {
  final engine = await audioProcessorEngine.engine();
  if (isPlayingSignal.value) {
    await engine.pauseAudio();
  } else {
    await engine.resumeAudio();
  }
}

/// Stop playback and reset position to the beginning.
Future<void> stopAudio() async {
  final engine = await audioProcessorEngine.engine();
  await engine.stopAudio();
  isPlayingSignal.value = false;
  playbackPositionSignal.value = Duration.zero;
  playbackFractionSignal.value = 0.0;
}

/// Seek to a fraction (0.0–1.0) of the loaded audio.
Future<void> seekTo(double fraction) async {
  final engine = await audioProcessorEngine.engine();
  await engine.seekAudio(fraction: fraction);
}

/// Set playback speed multiplier (1.0 = normal, 2.0 = double speed).
Future<void> setPlaybackSpeed(double multiplier) async {
  final engine = await audioProcessorEngine.engine();
  await engine.setPlaybackSpeed(multiplier: multiplier);
}
