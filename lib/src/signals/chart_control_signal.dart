import 'dart:math';

import 'package:signals/signals_flutter.dart';

// ─── Slider input signals ───────────────────────────────────────────────

/// Horizontal zoom: fraction of total data visible.
/// 1.0 = show all, 0.05 = zoomed in to 5%.
final xZoomSignal = signal(1.0);

/// Horizontal scroll position: center of the visible window.
/// Only effective when xZoom < 1.0 (i.e. zoomed in).
/// 0.0 = start of data, 1.0 = end of data.
final xPositionSignal = signal(0.5);

/// Vertical zoom: multiplier on the auto-detected Y range.
/// 1.0 = auto (full range), >1.0 = zoom in (less visible), <1.0 = zoom out.
final yZoomSignal = signal(1.0);

/// Vertical scroll position: vertical offset within the auto Y range.
/// Only effective when yZoom != 1.0.
/// 0.0 = bottom of data, 0.5 = center (default), 1.0 = top of data.
final yPositionSignal = signal(0.5);

// ─── Data-driven signals (updated from Rust events) ─────────────────────

/// Total data range — the upper bound of the audio index.
final chartMaxIndexSignal = signal(10000.0);

/// Auto-detected Y-axis range from Rust.
final yAutoMinSignal = signal(-0.5);
final yAutoMaxSignal = signal(0.5);

// ─── Computed visible range signals (read by ChartWidget) ───────────────

/// Visible X-axis minimum.
final xViewMinSignal = signal(0.0);

/// Visible X-axis maximum.
final xViewMaxSignal = signal(10000.0);

/// Visible Y-axis minimum.
final yViewMinSignal = signal(-0.5);

/// Visible Y-axis maximum.
final yViewMaxSignal = signal(0.5);

// ─── Fixed downsampling target (data resolution, independent of window) ─

const kDownsamplePoints = 2000;

// ─── Callback to notify ChartWidget that visible range changed ──────────

/// Set by ChartWidget.initState, called by recomputeVisibleRanges.
void Function()? onViewRangeChanged;

// ─── Recompute visible ranges from slider inputs ────────────────────────

/// Call this whenever any slider or data-bound signal changes.
/// Updates the visible range signals and returns the new (xStart, xEnd).
(double xStart, double xEnd) recomputeVisibleRanges() {
  final maxIdx = chartMaxIndexSignal.value;
  final xZoom = xZoomSignal.value;
  final xPos = xPositionSignal.value;

  // ── X-axis ──────────────────────────────────────────────────────────
  // viewableRange = portion of total data visible
  // When xZoom = 1.0 (full view): viewableRange = maxIdx, offset = 0 → always [0, maxIdx]
  // When xZoom < 1.0: position slider shifts the window
  final xViewableRange = maxIdx * xZoom;
  final xOffset = (xPos - 0.5) * (maxIdx - xViewableRange);
  final xCenter = maxIdx * 0.5 + xOffset;

  final xStart = (xCenter - xViewableRange / 2).clamp(0.0, maxIdx);
  final xEnd = (xCenter + xViewableRange / 2).clamp(0.0, maxIdx);
  xViewMinSignal.value = xStart;
  xViewMaxSignal.value = xEnd;

  // ── Y-axis ──────────────────────────────────────────────────────────
  // Same logic: when yZoom = 1.0 (auto), position has no effect
  // When yZoom > 1.0 (zoomed in), position shifts the window up/down
  final yAutoRange = yAutoMaxSignal.value - yAutoMinSignal.value;
  final yViewableRange = yAutoRange / yZoomSignal.value;
  final yMid = (yAutoMaxSignal.value + yAutoMinSignal.value) / 2;
  final yOffset = (yPositionSignal.value - 0.5) * (yAutoRange - yViewableRange);
  final yCenter = yMid + yOffset;

  final yHalf = max(yViewableRange / 2, 0.001);
  yViewMinSignal.value = yCenter - yHalf;
  yViewMaxSignal.value = yCenter + yHalf;

  onViewRangeChanged?.call();

  return (xStart, xEnd);
}
