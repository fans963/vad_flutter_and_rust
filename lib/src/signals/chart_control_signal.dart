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

// ─── Auto-computed zoom limits ──────────────────────────────────────────

/// Minimum X zoom fraction (zoomed in to ~100 points of detail).
final xZoomMinSignal = signal(0.01);

/// Y zoom range: allow zooming out to 0.1x and in to 10x by default.
final yZoomMaxSignal = signal(10.0);
final yZoomMinSignal = signal(0.1);

// ─── Fixed downsampling target (data resolution, independent of window) ─

const kDownsamplePoints = 2000;
const kMinVisiblePoints = 100;

(double xStart, double xEnd) recomputeVisibleRanges() {
  final maxIdx = chartMaxIndexSignal.value;
  final xZoom = xZoomSignal.value;
  final xPos = xPositionSignal.value;

  // ── Auto-compute zoom limits from data range ──────────────────────
  if (maxIdx > 0) {
    xZoomMinSignal.value = (kMinVisiblePoints / maxIdx).clamp(0.001, 1.0);
  }

  final yRange = yAutoMaxSignal.value - yAutoMinSignal.value;
  if (yRange > 0) {
    // Allow zooming out to show 10x the range, zooming in to show 1/100th
    yZoomMinSignal.value = 0.1;
    yZoomMaxSignal.value = max(10.0, (1.0 / yRange) * 50);
  }

  // ── X-axis ──────────────────────────────────────────────────────────
  final xViewableRange = maxIdx * xZoom;
  final xOffset = (xPos - 0.5) * (maxIdx - xViewableRange);
  final xCenter = maxIdx * 0.5 + xOffset;

  final xStart = (xCenter - xViewableRange / 2).clamp(0.0, maxIdx);
  final xEnd = (xCenter + xViewableRange / 2).clamp(0.0, maxIdx);
  xViewMinSignal.value = xStart;
  xViewMaxSignal.value = xEnd;

  // ── Y-axis ──────────────────────────────────────────────────────────
  final yViewableRange = yRange / yZoomSignal.value;
  final yMid = (yAutoMaxSignal.value + yAutoMinSignal.value) / 2;
  final yOffset = (yPositionSignal.value - 0.5) * (yRange - yViewableRange);
  final yCenter = yMid + yOffset;

  final yHalf = max(yViewableRange / 2, 0.001);
  yViewMinSignal.value = yCenter - yHalf;
  yViewMaxSignal.value = yCenter + yHalf;

  return (xStart, xEnd);
}
