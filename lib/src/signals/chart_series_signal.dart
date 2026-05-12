import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:vad/src/rust/api/core/engine.dart';
import 'package:vad/src/rust/api/types/chart.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';

// ─── Per-series metadata ─────────────────────────────────────────────────

class SeriesMeta {
  Color color;
  bool isVisible;

  SeriesMeta({required this.color, this.isVisible = true});
}

// ─── Global series manager ───────────────────────────────────────────────

class ChartSeriesManager {
  final _series = <String, SeriesMeta>{};

  /// Notifies ChartWidget to rebuild when any series state changes.
  final versionSignal = signal<int>(0);

  /// Currently selected series key, or null if nothing selected.
  final selectedKeySignal = signal<String?>(null);

  // ── Default palette ────────────────────────────────────────────────────

  static const _defaultColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.pink,
    Colors.amber,
  ];

  int _nextColorIndex = 0;

  Color _nextDefaultColor() {
    final c = _defaultColors[_nextColorIndex % _defaultColors.length];
    _nextColorIndex++;
    return c;
  }

  // ── Key helpers ─────────────────────────────────────────────────────────

  static String makeKey(String filePath, DataType dataType) =>
      '$filePath|${dataType.name}';

  static (String filePath, DataType dataType) parseKey(String key) {
    final idx = key.lastIndexOf('|');
    final filePath = key.substring(0, idx);
    final dtName = key.substring(idx + 1);
    final dataType = DataType.values.firstWhere((d) => d.name == dtName);
    return (filePath, dataType);
  }

  // ── CRUD ────────────────────────────────────────────────────────────────

  /// Register a new series (called when AddChart arrives).
  /// Returns the assigned color.
  Color registerSeries(String filePath, DataType dataType) {
    final key = makeKey(filePath, dataType);
    if (_series.containsKey(key)) return _series[key]!.color;

    _series[key] = SeriesMeta(color: _nextDefaultColor());
    versionSignal.value++;
    return _series[key]!.color;
  }

  /// Remove a series (called when RemoveChart arrives or user deletes).
  void unregisterSeries(String filePath, DataType dataType) {
    final key = makeKey(filePath, dataType);
    if (_series.remove(key) != null) {
      versionSignal.value++;
      if (selectedKeySignal.value == key) {
        selectedKeySignal.value = null;
      }
    }
  }

  /// Clear all series for a given file.
  void unregisterAllForFile(String filePath) {
    final prefix = '$filePath|';
    _series.removeWhere((key, _) {
      if (key.startsWith(prefix)) {
        if (selectedKeySignal.value == key) selectedKeySignal.value = null;
        return true;
      }
      return false;
    });
    versionSignal.value++;
  }

  // ── Color ───────────────────────────────────────────────────────────────

  Color getColor(String filePath, DataType dataType) {
    final key = makeKey(filePath, dataType);
    return _series[key]?.color ?? _nextDefaultColor();
  }

  void setColor(String filePath, DataType dataType, Color color) {
    final key = makeKey(filePath, dataType);
    final meta = _series[key];
    if (meta != null) {
      meta.color = color;
      versionSignal.value++;
    }
  }

  // ── Selection ───────────────────────────────────────────────────────────

  void select(String filePath, DataType dataType) {
    selectedKeySignal.value = makeKey(filePath, dataType);
  }

  void deselect() {
    selectedKeySignal.value = null;
  }

  String? get selectedKey => selectedKeySignal.value;

  bool isSelected(String filePath, DataType dataType) {
    return selectedKeySignal.value == makeKey(filePath, dataType);
  }

  SeriesMeta? getSelectedMeta() {
    final key = selectedKeySignal.value;
    if (key == null) return null;
    return _series[key];
  }

  // ── Visibility ───────────────────────────────────────────────────────

  bool isVisible(String filePath, DataType dataType) {
    return _series[makeKey(filePath, dataType)]?.isVisible ?? true;
  }

  void toggleVisibility(String filePath, DataType dataType) {
    final key = makeKey(filePath, dataType);
    final meta = _series[key];
    if (meta != null) {
      meta.isVisible = !meta.isVisible;
    } else {
      _series[key] = SeriesMeta(color: _nextDefaultColor(), isVisible: false);
    }
    versionSignal.value++;
  }

  // ── Query ────────────────────────────────────────────────────────────

  List<(String filePath, DataType dataType)> getAllSeries() {
    return _series.keys.map((key) => parseKey(key)).toList();
  }

  Future<void> deleteSelected() async {
    final key = selectedKeySignal.value;
    if (key == null) return;
    final (filePath, dataType) = parseKey(key);

    final engine = await audioProcessorEngine.engine();
    await engine.removeChart(filePath: filePath, dataType: dataType);

    unregisterSeries(filePath, dataType);
  }
}

/// Global singleton — the single source of truth for all series metadata.
final chartSeriesManager = ChartSeriesManager();
