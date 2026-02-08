import 'package:signals/signals_flutter.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

final supportAudioFormatSignal = Signal<List<String>>([
  'wav',
  'mp3',
  'aac',
  'flac',
  'ogg',
  'm4a',
]);

final supportAudioFormatSignalForDrag = Signal([
  Formats.wav,
  Formats.mp3,
  Formats.aac,
  Formats.flac,
  Formats.ogg,
  Formats.m4a,
]);
