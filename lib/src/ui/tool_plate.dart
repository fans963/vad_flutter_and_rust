import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';
import 'package:vad/src/signals/chart_control_signal.dart';
import 'package:vad/src/signals/chart_series_signal.dart';
import 'package:vad/src/signals/page_controller_signal.dart';
import 'package:vad/src/util/drag_handler.dart';

class ToolPlate extends StatelessWidget {
  const ToolPlate({super.key});

  @override
  Widget build(BuildContext context) {
    final widgets = [
      const HomePanel(),
      const InfoPanel(),
      const ControlPanel(),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: toolPlateHeightSignal.value,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            GenericDragHandle(
              onDragUpdate: (double newHeight) {
                final screenHeight = MediaQuery.of(context).size.height;
                toolPlateHeightSignal.value = newHeight.clamp(
                  50.0,
                  screenHeight * 0.6,
                );
              },
              onDragStart: () {
                return toolPlateHeightSignal.value;
              },
            ),
            Expanded(
              child: PageView(
                controller: pageControllerSignal.value,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) => pageIndexSignal.value = index,
                children: widgets,
              ),
            ),
          ],
        ),
        ),
      );
     
    });
  }
}

class HomePanel extends StatelessWidget {
  const HomePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: [
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: const AssetImage(
                    'assets/image/fan_avatar.png',
                  ),
                ),
                SizedBox(width: 20),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: const AssetImage(
                    'assets/image/liu_avatar.jpg',
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            AutoSizeText(
              'Developer: fans963 & 🐂津哥',
              style: Theme.of(context).textTheme.headlineSmall,
              maxLines: 1,
              minFontSize: 14,
            ),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: AutoSizeText(
                      'Project Repository: ',
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 1,
                      minFontSize: 12,
                    ),
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: () async {
                        final url = Uri.parse(
                          'https://github.com/fans963/vad_flutter_and_rust',
                        );
                        await launchUrl(url);
                      },
                      child: AutoSizeText(
                        'https://github.com/fans963/vad_flutter_and_rust',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                        maxLines: 1,
                        minFontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('信息', style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  bool _engineConfigured = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _ensureEngineConfigured() async {
    if (_engineConfigured) return;
    _engineConfigured = true;
    final engine = await audioProcessorEngine.engine();
    await engine.setDownSamplePointsNum(
      pointsNum: BigInt.from(kDownsamplePoints),
    );
  }

  void _scheduleEngineUpdate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), () {
      _applyToEngine();
    });
  }

  Future<void> _applyToEngine() async {
    final maxIdx = chartMaxIndexSignal.value;
    if (maxIdx <= 0) return;

    await _ensureEngineConfigured();

    final (xStart, xEnd) = recomputeVisibleRanges();

    final engine = await audioProcessorEngine.engine();
    await engine.setIndexRange(start: xStart, end: xEnd);
  }

  void _showColorPicker() {
    final meta = chartSeriesManager.getSelectedMeta();
    if (meta == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('选择颜色'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: meta.color,
            onColorChanged: (color) {
              meta.color = color;
              chartSeriesManager.versionSignal.value++;
            },
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final key = chartSeriesManager.selectedKey;
    if (key == null) return;

    final (filePath, dataType) = ChartSeriesManager.parseKey(key);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除 "$filePath" 的 ${dataType.name} 数据？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await chartSeriesManager.deleteSelected();
    }
  }

  Widget _buildSelectedSeriesBar(BuildContext context) {
    final selectedKey = chartSeriesManager.selectedKeySignal.value;
    final meta = chartSeriesManager.getSelectedMeta();

    if (selectedKey == null || meta == null) {
      return const SizedBox.shrink();
    }

    final (filePath, dataType) = ChartSeriesManager.parseKey(selectedKey);
    final fileName = filePath.split('/').last;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: meta.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: meta.color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已选中: $fileName — ${dataType.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Color indicator + picker
              GestureDetector(
                onTap: _showColorPicker,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: meta.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _showColorPicker,
                icon: const Icon(Icons.colorize, size: 18),
                label: const Text('换色'),
              ),
              const Spacer(),
              // Delete button
              TextButton.icon(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                label: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
              // Deselect button
              TextButton(
                onPressed: () => chartSeriesManager.deselect(),
                child: const Text('取消选中'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final maxIdx = chartMaxIndexSignal.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── X-axis position slider ──
            Text(
              '时间轴位置',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                const Text('0%'),
                Expanded(
                  child: Slider(
                    value: xPositionSignal.value,
                    min: 0.0,
                    max: 1.0,
                    divisions: 200,
                    onChanged: (v) {
                      xPositionSignal.value = v;
                      recomputeVisibleRanges();
                      _scheduleEngineUpdate();
                    },
                  ),
                ),
                const Text('100%'),
              ],
            ),
            const SizedBox(height: 8),

            // ── X-axis zoom slider ──
            Text(
              '缩放 (X)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                Text('${(xZoomSignal.value * 100).toStringAsFixed(0)}%'),
                Expanded(
                  child: Slider(
                    value: xZoomSignal.value,
                    min: 0.05,
                    max: 1.0,
                    divisions: 95,
                    onChanged: (v) {
                      xZoomSignal.value = v;
                      recomputeVisibleRanges();
                      _scheduleEngineUpdate();
                    },
                  ),
                ),
                const Text('100%'),
              ],
            ),
            const SizedBox(height: 8),

            // ── Y-axis zoom slider ──
            Text(
              '缩放 (Y)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                Text('${yZoomSignal.value.toStringAsFixed(1)}x'),
                Expanded(
                  child: Slider(
                    value: yZoomSignal.value,
                    min: 0.1,
                    max: 5.0,
                    divisions: 49,
                    onChanged: (v) {
                      yZoomSignal.value = v;
                      recomputeVisibleRanges();
                      _scheduleEngineUpdate();
                    },
                  ),
                ),
                const Text('5.0x'),
              ],
            ),
            const SizedBox(height: 8),

            // ── Y-axis position slider ──
            Text(
              '位置 (Y)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                const Text('↓'),
                Expanded(
                  child: Slider(
                    value: yPositionSignal.value,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    onChanged: (v) {
                      yPositionSignal.value = v;
                      recomputeVisibleRanges();
                      _scheduleEngineUpdate();
                    },
                  ),
                ),
                const Text('↑'),
              ],
            ),
            const SizedBox(height: 8),

            // ── Selected series actions ──
            _buildSelectedSeriesBar(context),

            // ── Info bar ──
            Text(
              'X: ${xViewMinSignal.value.toStringAsFixed(0)} – ${xViewMaxSignal.value.toStringAsFixed(0)}  |  '
              'Y: ${yViewMinSignal.value.toStringAsFixed(3)} – ${yViewMaxSignal.value.toStringAsFixed(3)}  |  '
              'Total: ${maxIdx.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    });
  }
}
